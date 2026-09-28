#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""重出立绘「原图」（Local Dream 出图，本脚本不做抠图），抠图交给 BiRefNet。

与 gen_assets.py 的分工
-----------------------
* gen_assets.py  —— 出图 + 自带「洪水填充抠图」。那套是给纯色底准备的粗糙方案，
                    会残留灰色抗锯齿边、以及模型自己画的漂浮色块（README 已知边界）。
* 本脚本        —— 只出图，保留原始背景；抠图交给 ``birefnet-cutout``（语义分割），
                    构图体检交给 ``check_sprites.py``。

流程
----
    python3 tools/regen_sprites.py                 # 出原图到 tools/_raw_sprites/
    python3 tools/regen_sprites.py --only shiori   # 只重出某几张
    birefnet-cutout tools/_raw_sprites/*.png --outdir assets/char --json
    python3 tools/check_sprites.py                 # 构图体检（顶/左/右边缘）

★ CLIP 上限 77 token（本脚本存在的第二个理由）
-----------------------------------------------
出图前会调 /tokenize 核算「质量前缀 + 提示词」与「负面提示词」。
**超过 77 的话服务端会静默丢弃尾部**，不报错。实测旧版立绘提示词是 104 token，
被丢掉的正是这些标签::

    thin red string bracelet on left wrist, cowboy shot, standing,
    facing viewer, head fully visible, cel shading, clean lineart

也就是「哥哥的红绳」这个全书最重要的道具、以及全部构图控制（这才是出图反复
「构图出画」重抽的真正原因）。负面提示词同理（旧版 193 token，连 lowres /
worst quality / bad anatomy 都被丢了）。

所以本脚本发现溢出会**直接中止**，不生成——宁可报错，也不要再产出错的立绘。
"""
import argparse
import json
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_assets as GA  # noqa: E402  复用 HTTP / PNG 编码 / 出图逻辑

RAW_DIR = os.path.join(GA.HERE, "_raw_sprites")
CLIP_MAX = 77


def clip_tokens(text):
    """返回 (token 数, 溢出字符下标)。溢出下标 >= 0 表示尾部会被丢弃。"""
    code, resp = GA.post_json(GA.GEN + "/tokenize", {"prompt": text}, timeout=30)
    if code != 200 or not isinstance(resp, dict):
        raise RuntimeError("tokenize 异常：%s %s" % (code, resp))
    return int(resp.get("count", -1)), int(resp.get("overflow_offset", -1))


def check_clip(items, qp, default_neg):
    """出图前统一核算 token，返回不合格的 id 列表。"""
    bad = []
    for it in items:
        body = it["prompt"] if it.get("no_prefix") else qp + it["prompt"]
        n, off = clip_tokens(body)
        neg = it.get("negative", default_neg)
        nn, noff = clip_tokens(neg)
        problems = []
        if off >= 0:
            problems.append("提示词溢出，尾部被丢弃 -> %r" % body[off:][:70])
        if noff >= 0:
            problems.append("负面溢出，尾部被丢弃 -> %r" % neg[noff:][:70])
        tag = "OK"
        if problems:
            tag = "!! " + "; ".join(problems)
            bad.append(it["id"])
        GA.log("token %-30s prompt=%3d/%d negative=%3d/%d  %s"
               % (it["id"], n, CLIP_MAX, nn, CLIP_MAX, tag))
    return bad


def edge_outside(raw, w, h, ch, tol=40):
    """在裸像素上估「四条边上有没有主体」，返回 (顶, 左, 右, 下) 的主体像素数。

    判据刻意**不跟某个参考色比色差**：SD 常在这种「平灰底」上加一层柔和渐变
    （中心亮、四周暗），实测色差法会把渐变的角落误判成主体（假出画）。
    所以改看像素本身的性质——背景是提示词要求的低饱和中灰，而
    头发很暗、衬衣很亮、皮肤饱和度高，这三条都躲得开渐变。
    """
    def is_subject(i):
        r = raw[i * ch]
        g = raw[i * ch + 1]
        b = raw[i * ch + 2]
        lum = (r * 299 + g * 587 + b * 114) // 1000
        sat = max(r, g, b) - min(r, g, b)
        return lum < 78 or lum > 240 or sat > 60

    top = sum(1 for x in range(w) if is_subject(x))
    bot = sum(1 for x in range(w) if is_subject((h - 1) * w + x))
    left = sum(1 for y in range(h) if is_subject(y * w))
    right = sum(1 for y in range(h) if is_subject(y * w + w - 1))
    return top, left, right, bot


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="只处理 id 含该子串的条目")
    ap.add_argument("--force", action="store_true", help="已存在的原图也重出")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--steps", type=int, default=0, help="覆盖 manifest 里的 steps")
    ap.add_argument("--tries", type=int, default=6, help="每张最多重抽几次（换种子换构图）")
    ap.add_argument("--outdir", default=RAW_DIR)
    args = ap.parse_args()

    with open(GA.MANIFEST, encoding="utf-8") as f:
        man = json.load(f)
    model = man["model"]
    qp = man.get("quality_prefix", "")
    default_neg = man.get("negative", "")

    items = [a for a in man["assets"] if a["kind"] == "char"]
    if args.only:
        items = [a for a in items if args.only in a["id"]]
    if args.steps:
        items = [dict(a, steps=args.steps) for a in items]

    todo = []
    for it in items:
        out = os.path.join(args.outdir, it["id"] + ".png")
        if os.path.exists(out) and not args.force:
            continue
        todo.append((it, out))

    GA.log("立绘重出：命中 %d 项，待出图 %d 项（模型 %s）" % (len(items), len(todo), model))
    if not todo:
        return 0
    if args.dry_run:
        for it, out in todo:
            GA.log("  待出图 %s  %dx%d steps=%d" % (it["id"], it["w"], it["h"], it.get("steps", 12)))
        return 0

    # 服务 + 模型
    try:
        info = GA.get_json(GA.CTL + "/info")
    except Exception as e:
        sys.exit("[FAIL] 连不上 Local Dream 控制口：%s（受控模式没开？）" % e)
    GA.log("Local Dream %s" % info.get("version"))
    st = GA.get_json(GA.CTL + "/status")
    if st.get("serving_model_id") != model:
        code, resp = GA.post_json(GA.CTL + "/select", {"model_id": model}, timeout=60)
        GA.log("select %s -> %s %s" % (model, code, resp))
        if code != 200:
            sys.exit("[FAIL] 模型切换失败：%s" % resp)
    if not GA.wait_gen_port():
        sys.exit("[FAIL] 生成口 240s 未就绪")

    # ★ token 护栏：溢出就停，不生成
    bad = check_clip(items, qp, default_neg)
    if bad:
        sys.exit("[FAIL] 以下条目提示词/负面超出 CLIP %d token，尾部会被静默丢弃，已中止：%s"
                 % (CLIP_MAX, ", ".join(bad)))
    GA.log("token 核算通过（全部 ≤ %d）" % CLIP_MAX)

    os.makedirs(args.outdir, exist_ok=True)
    ok, fail = 0, []
    t_all = time.time()
    for i, (it, out) in enumerate(todo, 1):
        t0 = time.time()
        GA.log("[%d/%d] %s %dx%d steps=%d ..."
               % (i, len(todo), it["id"], it["w"], it["h"], it.get("steps", 12)))
        done = False
        for attempt in range(1, args.tries + 1):
            # 显式换随机种子：服务端对 seed=-1 不回真种子，用 -1 重抽等于每次出同一张
            seed = random.randint(1, 2147483646)
            try:
                raw, w, h, seed = GA.generate(it, model, qp, default_neg, seed_override=seed)
            except Exception as e:
                GA.log("  !! 第 %d 次失败：%s" % (attempt, e))
                continue
            # 构图出画当场重抽（顶边主体像素过多 = 头顶被切）
            if len(raw) in (w * h * 3, w * h * 4):
                ch = 3 if len(raw) == w * h * 3 else 4
                top, left, right, _bot = edge_outside(raw, w, h, ch)
                if top > int(w * 0.05) or left > int(h * 0.08) or right > int(h * 0.08):
                    GA.log("  ~~ 第 %d 次：构图出画（顶 %d / 左 %d / 右 %d），换种子重抽"
                           % (attempt, top, left, right))
                    continue
            # 统一落成 RGBA：项目里的 clean_sprites.read_rgba / check_sprites / qc_sprites
            # 只认 4 通道 PNG（color type 6），3 通道会被当成「读不出」。
            if raw[:8] == b"\x89PNG\r\n\x1a\n":
                with open(out, "wb") as f:      # 服务端偶尔直接回整张 PNG
                    f.write(raw)
            else:
                n = w * h
                if len(raw) == n * 4:
                    rgba = bytearray(raw)
                elif len(raw) == n * 3:
                    rgba = bytearray(n * 4)
                    for k in range(n):
                        rgba[k * 4] = raw[k * 3]
                        rgba[k * 4 + 1] = raw[k * 3 + 1]
                        rgba[k * 4 + 2] = raw[k * 3 + 2]
                        rgba[k * 4 + 3] = 255
                else:
                    GA.log("  !! 像素长度异常 %d（期望 %d 或 %d），跳过" % (len(raw), n * 3, n * 4))
                    continue
                GA.write_png(out, rgba, w, h, 4)
            GA.log("  ok %.1fs seed=%s -> %s" % (time.time() - t0, seed, os.path.relpath(out, GA.ROOT)))
            ok += 1
            done = True
            break
        if not done:
            fail.append(it["id"])
            GA.log("  XX %s 出图失败" % it["id"])

    GA.log("出图完成：成功 %d / 失败 %d，总耗时 %.1f 分钟"
           % (ok, len(fail), (time.time() - t_all) / 60))
    if fail:
        GA.log("   FAILED %s" % ", ".join(fail))
        return 1
    GA.log("下一步：birefnet-cutout %s/*.png --outdir %s --json  然后 python3 tools/check_sprites.py"
           % (os.path.relpath(args.outdir, GA.ROOT), "assets/char"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
