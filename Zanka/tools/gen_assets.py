#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《残夏》批量美术生成器 —— 走 Local Dream 受控模式 HTTP 接口。

特性：
  * 可断点续跑：已存在的输出文件默认跳过（--force 覆盖）
  * 角色立绘自动抠图（纯 stdlib，边界洪水填充 + 边缘羽化），产出 RGBA PNG
  * 单张失败不影响整体，最后打印汇总
用法：
  python3 gen_assets.py                 # 生成全部缺失资产
  python3 gen_assets.py --only bg_      # 只生成 id 含该子串的
  python3 gen_assets.py --force         # 全部重生成
  python3 gen_assets.py --dry-run       # 只打印计划
"""
import argparse
import base64
import json
import os
import random
import struct
import sys
import time
import urllib.error
import urllib.request
import zlib
from collections import deque

CTL = "http://127.0.0.1:8808"
GEN = "http://127.0.0.1:8081"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                 # Zanka/
MANIFEST = os.path.join(HERE, "asset_manifest.json")
LOG = os.path.join(HERE, "gen_progress.log")

KIND_DIR = {"bg": "assets/bg", "char": "assets/char", "cg": "assets/cg", "ui": "assets/ui"}


def log(msg):
    line = "[%s] %s" % (time.strftime("%H:%M:%S"), msg)
    print(line, flush=True)
    try:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass


# ---------------------------------------------------------------- HTTP 小工具

def _req(url, payload=None, timeout=60):
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    return urllib.request.urlopen(
        urllib.request.Request(url, data=data, headers=headers), timeout=timeout)


def get_json(url, timeout=15):
    with _req(url, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def post_json(url, payload, timeout=60):
    try:
        with _req(url, payload, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8", "replace"))
        except Exception:
            return e.code, {"error": str(e)}


def wait_gen_port(deadline=240):
    t0 = time.time()
    while time.time() - t0 < deadline:
        try:
            with _req(GEN + "/health", timeout=4) as r:
                if r.status == 200:
                    return True
        except Exception:
            pass
        time.sleep(2)
    return False


# ---------------------------------------------------------------- PNG 编解码

def _chunk(tag, body):
    c = tag + body
    return struct.pack(">I", len(body)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)


def write_png(path, px, w, h, ch):
    """px = 裸像素 (RGB 或 RGBA)。"""
    colour = {1: 0, 2: 4, 3: 2, 4: 6}[ch]
    stride = w * ch
    rows = b"".join(b"\x00" + px[y * stride:(y + 1) * stride] for y in range(h))
    png = (b"\x89PNG\r\n\x1a\n"
           + _chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, colour, 0, 0, 0))
           + _chunk(b"IDAT", zlib.compress(rows, 6))
           + _chunk(b"IEND", b""))
    tmp = path + ".part"
    with open(tmp, "wb") as f:
        f.write(png)
    os.replace(tmp, path)
    return len(png)


# ---------------------------------------------------------------- 抠图

def _flood(mask, w, h):
    """从四边洪水填充 mask（bytearray，1=可通行）。返回 visited。"""
    n = w * h
    visited = bytearray(n)
    dq = deque()
    for x in range(w):
        for idx in (x, (h - 1) * w + x):
            if mask[idx] and not visited[idx]:
                visited[idx] = 1
                dq.append(idx)
    for y in range(h):
        for idx in (y * w, y * w + w - 1):
            if mask[idx] and not visited[idx]:
                visited[idx] = 1
                dq.append(idx)
    while dq:
        q = dq.popleft()
        x = q % w
        if x > 0 and mask[q - 1] and not visited[q - 1]:
            visited[q - 1] = 1
            dq.append(q - 1)
        if x < w - 1 and mask[q + 1] and not visited[q + 1]:
            visited[q + 1] = 1
            dq.append(q + 1)
        if q >= w and mask[q - w] and not visited[q - w]:
            visited[q - w] = 1
            dq.append(q - w)
        if q < n - w and mask[q + w] and not visited[q + w]:
            visited[q + w] = 1
            dq.append(q + w)
    return visited


def _to_rgba(rgb, w, h, visited):
    n = w * h
    alpha = bytearray(n)
    for i in range(n):
        alpha[i] = 0 if visited[i] else 255
    # 1px 羽化，减轻锯齿
    for y in range(h):
        base = y * w
        for x in range(w):
            i = base + x
            if not alpha[i]:
                continue
            if (x > 0 and not alpha[i - 1]) or (x < w - 1 and not alpha[i + 1]) \
               or (y > 0 and not alpha[i - w]) or (y < h - 1 and not alpha[i + w]):
                alpha[i] = 150
    out = bytearray(n * 4)
    for i in range(n):
        o3, o4 = i * 3, i * 4
        out[o4] = rgb[o3]
        out[o4 + 1] = rgb[o3 + 1]
        out[o4 + 2] = rgb[o3 + 2]
        out[o4 + 3] = alpha[i]
    return bytes(out)


def cutout_rgb(rgb, w, h):
    """自适应纯色背景抠图。

    取四边像素的中位数当背景参考色（不假设是白色/绿色），洪水填充去掉连通区域。
    关键防呆：如果参考色本身接近纯白，说明角色可能穿白衣服，此时把容差压到很小，
    避免背景白顺着衣服白一路填进去（实测踩过这个坑）。
    """
    n = w * h
    stride = w * 3
    samples = []
    for x in range(0, w, 2):
        samples.append(rgb[x * 3:x * 3 + 3])
        samples.append(rgb[(h - 1) * stride + x * 3:(h - 1) * stride + x * 3 + 3])
    for y in range(0, h, 2):
        samples.append(rgb[y * stride:y * stride + 3])
        samples.append(rgb[y * stride + (w - 1) * 3:y * stride + (w - 1) * 3 + 3])
    if not samples:
        return None, 0.0
    mid = len(samples) // 2
    rr = sorted(v[0] for v in samples)[mid]
    rg = sorted(v[1] for v in samples)[mid]
    rb = sorted(v[2] for v in samples)[mid]
    lum = 0.299 * rr + 0.587 * rg + 0.114 * rb
    # 近白 -> 收紧（保护白衬衫）；近黑 -> 也收紧（保护黑发，否则黑底会把黑发一起吃掉）
    # 近白/浅灰 -> 收紧（保护白衬衫、浅灰上衣）；近黑 -> 收紧（保护黑发）
    tol = 15 if lum > 192 else (18 if lum < 34 else 46)
    tol2 = tol * tol

    mask = bytearray(n)
    for i in range(n):
        o = i * 3
        dr = rgb[o] - rr
        dg = rgb[o + 1] - rg
        db = rgb[o + 2] - rb
        if dr * dr + dg * dg + db * db < tol2:
            mask[i] = 1

    vis = _flood(mask, w, h)
    ratio = sum(vis) / n
    if 0.04 <= ratio <= 0.92:
        return _to_rgba(rgb, w, h, vis), ratio
    return None, ratio


def top_edge_opaque(rgba, w, h, th=120):
    """顶边不透明像素数。>0 说明头顶被画布切掉了。"""
    n = 0
    for x in range(w):
        if rgba[(x) * 4 + 3] > th:
            n += 1
    return n


def side_edge_opaque(rgba, w, h, th=120):
    left = sum(1 for y in range(h) if rgba[(y * w) * 4 + 3] > th)
    right = sum(1 for y in range(h) if rgba[(y * w + w - 1) * 4 + 3] > th)
    return left, right

def bg_uniformity(rgb, w, h, ring=8):
    """量一下「背景有多纯」。

    返回 (主色覆盖率, 亮度标准差)。
    覆盖率低 / 标准差异常大，说明模型画的是渐变或多色背景——
    这种图无论用什么抠图算法都会留残影（背景和衣服颜色叠在一起，无从区分）。
    与其事后修，不如在出图阶段就否掉。
    """
    samples = []
    for x in range(0, w, 2):
        for y in list(range(ring)) + list(range(h - ring, h)):
            o = (y * w + x) * 3
            samples.append((rgb[o], rgb[o + 1], rgb[o + 2]))
    for y in range(0, h, 2):
        for x in list(range(ring)) + list(range(w - ring, w)):
            o = (y * w + x) * 3
            samples.append((rgb[o], rgb[o + 1], rgb[o + 2]))
    if not samples:
        return 0.0, 999.0
    mid = len(samples) // 2
    rr = sorted(v[0] for v in samples)[mid]
    rg = sorted(v[1] for v in samples)[mid]
    rb = sorted(v[2] for v in samples)[mid]
    near = 0
    lums = []
    for (r, g, b) in samples:
        if abs(r - rr) + abs(g - rg) + abs(b - rb) < 90:
            near += 1
        lums.append(0.299 * r + 0.587 * g + 0.114 * b)
    coverage = near / float(len(samples))
    mean = sum(lums) / len(lums)
    var = sum((v - mean) ** 2 for v in lums) / len(lums)
    return coverage, var ** 0.5

# ---------------------------------------------------------------- 生成单张

def generate(item, model, quality_prefix, default_neg, timeout=1800, seed_override=None):
    prompt = item["prompt"] if item.get("no_prefix") else (quality_prefix + item["prompt"])
    neg = item.get("negative", default_neg)
    payload = {
        "prompt": prompt,
        "negative_prompt": neg,
        "steps": item.get("steps", 12),
        "cfg": item.get("cfg", 7.0),
        "width": item["w"],
        "height": item["h"],
        "seed": seed_override if seed_override is not None else item.get("seed", -1),
        "scheduler": item.get("scheduler", "dpm"),
    }
    result = None
    last = -1
    with _req(GEN + "/generate", payload, timeout=timeout) as resp:
        for raw in resp:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            try:
                d = json.loads(line[5:].strip())
            except Exception:
                continue
            if d.get("type") == "progress":
                st = d.get("step")
                if st != last and d.get("total_steps"):
                    last = st
            elif d.get("image"):
                result = d
                break
            elif d.get("type") == "error":
                raise RuntimeError(json.dumps(d, ensure_ascii=False))
    if not result:
        raise RuntimeError("流结束但没拿到图像")
    blob = base64.b64decode(result["image"])
    w, h = result.get("width"), result.get("height")
    ch = result.get("channels", 3)
    if result.get("format") == "png":
        return blob, w, h, result.get("seed")
    if len(blob) != w * h * ch:
        raise RuntimeError("像素长度不匹配 %d != %dx%dx%d" % (len(blob), w, h, ch))
    return blob, w, h, result.get("seed")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    with open(MANIFEST, encoding="utf-8") as f:
        man = json.load(f)
    model = man["model"]
    qp = man.get("quality_prefix", "")
    neg = man.get("negative", "")
    items = [a for a in man["assets"] if args.only in a["id"]] if args.only else man["assets"]

    todo = []
    for it in items:
        out = os.path.join(ROOT, KIND_DIR[it["kind"]], it["id"] + ".png")
        if os.path.exists(out) and not args.force:
            continue
        todo.append((it, out))

    log("计划 %d 项，待生成 %d 项（模型 %s）" % (len(items), len(todo), model))
    if args.dry_run:
        for it, out in todo:
            log("  待生成 %s  %dx%d" % (it["id"], it["w"], it["h"]))
        return

    # 确认服务 + 模型
    try:
        info = get_json(CTL + "/info")
    except Exception as e:
        sys.exit("[FAIL] 连不上 Local Dream 控制口：%s（受控模式没开？）" % e)
    log("Local Dream %s" % info.get("version"))
    st = get_json(CTL + "/status")
    if st.get("serving_model_id") != model:
        code, resp = post_json(CTL + "/select", {"model_id": model}, timeout=60)
        log("select %s -> %s %s" % (model, code, resp))
        if code != 200:
            sys.exit("[FAIL] 模型切换失败：%s" % resp)
    if not wait_gen_port():
        sys.exit("[FAIL] 生成口 240s 未就绪")

    ok, fail = 0, []
    t_all = time.time()
    for i, (it, out) in enumerate(todo, 1):
        os.makedirs(os.path.dirname(out), exist_ok=True)
        t0 = time.time()
        log("[%d/%d] %s %dx%d steps=%d ..." % (i, len(todo), it["id"], it["w"], it["h"], it.get("steps", 12)))
        payload = None
        max_try = 6 if it.get("cutout") else 1   # 只想换种子换构图，不动提示词
        base_item = dict(it)
        for attempt in range(1, max_try + 1):
            # 每次显式换随机种子：服务端对 seed=-1 不回真种子，靠 -1 重抽等于每次出同一张
            cur = dict(base_item)
            cur_seed = random.randint(1, 2147483646)
            try:
                raw, w, h, seed = generate(cur, model, qp, neg, seed_override=cur_seed)
            except Exception as e:
                log("  !! 失败：%s" % e)
                if attempt < max_try:
                    continue
                payload = None
                break
            if not it.get("cutout"):
                payload = ("rgb", raw, w, h, None)
                break
            try:
                res = cutout_rgb(raw, w, h)
            except Exception as e:
                log("  !! 抠图异常：%s" % e)
                continue
            if res is None or res[0] is None:
                ratio = res[1] if res else -1.0
                log("  ~~ 第 %d 次：抠图失败(背景占比 %.2f)，换种子重抽" % (attempt, ratio))
                continue
            rgba, ratio = res
            cov, sd = bg_uniformity(raw, w, h)
            if cov < 0.82 or sd > 24:
                log("  ~~ 第 %d 次：背景不纯（主色覆盖 %.2f / 亮度标准差 %.1f），换种子重抽"
                    % (attempt, cov, sd))
                continue
            top = top_edge_opaque(rgba, w, h)
            left, right = side_edge_opaque(rgba, w, h)
            if top > 20 or left > 80 or right > 80:
                log("  ~~ 第 %d 次：构图出画（顶 %d / 左 %d / 右 %d，阈值 20/80/80），换种子重抽"
                    % (attempt, top, left, right))
                continue
            log("  ~~ 抠图完成 背景占比 %.2f（顶边留白 %d）" % (ratio, top))
            payload = ("rgba", rgba, w, h, ratio)
            break
        if payload is None:
            fail.append((it["id"], "多次重抽仍未得到合格构图"))
            log("  XX %s：多次重抽仍不合格，跳过" % it["id"])
            continue
        try:
            kind, data, w, h, _r = payload
            if kind == "rgba":
                write_png(out, data, w, h, 4)
            else:
                write_png(out, data, w, h, 3)
        except Exception as e:
            log("  !! 写盘失败：%s" % e)
            fail.append((it["id"], "write:" + str(e)[:100]))
            continue
        ok += 1
        log("  ok %.1fs seed=%s -> %s" % (time.time() - t0, seed, os.path.relpath(out, ROOT)))

    log("完成：成功 %d / 失败 %d，总耗时 %.1f 分钟" % (ok, len(fail), (time.time() - t_all) / 60))
    for fid, err in fail:
        log("   FAILED %s : %s" % (fid, err))
    if fail:
        sys.exit(1)


if __name__ == "__main__":
    main()
