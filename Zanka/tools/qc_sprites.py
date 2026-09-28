#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""立绘质检：不靠肉眼也能查的量化指标 + 一张对比总览图。

为什么需要它
------------
立绘的问题分两类，check_sprites.py 只覆盖了第一类：

1. **构图出画**（头顶被切）—— check_sprites.py 已经会查。
2. **内容不对 + 抠图脏** —— 本脚本负责：
   * ``red``：**红色像素簇**。企划里栞「左手腕有一根从不摘的红绳，是哥哥的」，
     而旧提示词因为超出 CLIP 77 token，``thin red string bracelet on left wrist``
     被服务端静默丢弃——所以旧立绘**根本没有红绳**。这个指标就是用来证明修好了：
     旧图≈0 簇，新图应出现一小块高饱和红。
   * ``blobs``：**孤立碎块**（alpha 连通域）。README 的已知边界里写的
     「模型自己加的漂浮色块」就是这个；BiRefNet 抠图后不应该再有。
   * ``soft``：半透明边缘像素占比。洪水填充抠图会留下大片灰色抗锯齿晕，
     语义抠图的过渡带应该很窄。
   * ``edge``：顶/左/右/下四条边上的不透明像素数。

用法
----
    python3 tools/qc_sprites.py                          # 体检 assets/char
    python3 tools/qc_sprites.py --dir tools/_matte       # 体检别的目录
    python3 tools/qc_sprites.py --compare <旧目录>        # 与旧版逐张对比
    python3 tools/qc_sprites.py --sheet 预览/立绘总览.png  # 另存对比总览图
"""
import argparse
import json
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_sprites import read_rgba, write_rgba  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")
ALPHA_SOLID = 128


def analyse(w, h, px):
    """返回一张立绘的量化指标。"""
    n = w * h
    opaque = 0
    soft = 0
    red = []
    minx, miny, maxx, maxy = w, h, -1, -1
    for i in range(n):
        a = px[i * 4 + 3]
        if a == 0:
            continue
        x, y = i % w, i // w
        if a >= ALPHA_SOLID:
            opaque += 1
            if x < minx:
                minx = x
            if x > maxx:
                maxx = x
            if y < miny:
                miny = y
            if y > maxy:
                maxy = y
            r, g, b = px[i * 4], px[i * 4 + 1], px[i * 4 + 2]
            # 高饱和红：红绳、也排除掉肤色/唇色（它们 r-g 差没那么大）
            if r > 140 and r - g > 70 and r - b > 70:
                red.append((x, y))
        else:
            soft += 1

    # 四条边的不透明像素
    edge = {"top": 0, "left": 0, "right": 0, "bottom": 0}
    for x in range(w):
        if px[(0 * w + x) * 4 + 3] >= ALPHA_SOLID:
            edge["top"] += 1
        if px[((h - 1) * w + x) * 4 + 3] >= ALPHA_SOLID:
            edge["bottom"] += 1
    for y in range(h):
        if px[(y * w + 0) * 4 + 3] >= ALPHA_SOLID:
            edge["left"] += 1
        if px[(y * w + w - 1) * 4 + 3] >= ALPHA_SOLID:
            edge["right"] += 1

    # alpha 连通域：主体 + 孤立碎块
    seen = bytearray(n)
    comps = []
    for start in range(n):
        if seen[start] or px[start * 4 + 3] < ALPHA_SOLID:
            continue
        q = deque([start])
        seen[start] = 1
        size = 0
        while q:
            cur = q.popleft()
            size += 1
            cx, cy = cur % w, cur // w
            for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                if 0 <= nx < w and 0 <= ny < h:
                    k = ny * w + nx
                    if not seen[k] and px[k * 4 + 3] >= ALPHA_SOLID:
                        seen[k] = 1
                        q.append(k)
        comps.append(size)
    comps.sort(reverse=True)
    main = comps[0] if comps else 0
    # 碎块：不属于主体、且面积够大（>0.05% 画面）的连通域
    blobs = [c for c in comps[1:] if c > n * 0.0005]

    return {
        "size": "%dx%d" % (w, h),
        "opaque": opaque,
        "coverage": round(opaque / float(n) * 100.0, 1),
        "soft": soft,
        "soft_pct": round(soft / float(max(1, opaque + soft)) * 100.0, 1),
        "bbox": [minx, miny, maxx, maxy] if maxx >= 0 else None,
        "headroom": miny if maxx >= 0 else -1,
        "edge": edge,
        "blobs": len(blobs),
        "blob_px": sum(blobs),
        "comps": len(comps),
        "red": len(red),
        "red_bbox": _box(red) if red else None,
    }


def _box(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return [min(xs), min(ys), max(xs), max(ys)]


def load(path):
    r = read_rgba(path)
    if r is None:
        return None
    w, h, px = r
    return w, h, px


def sheet(paths, out, cols=4, cell=248, bg=(38, 42, 52), checker=(54, 60, 72)):
    """把若干立绘拼成一张对比总览图（透明处铺棋盘格，能看出边缘脏不脏）。"""
    rows = (len(paths) + cols - 1) // cols
    W, H = cols * cell, rows * cell
    canvas = bytearray(W * H * 4)
    for y in range(H):
        for x in range(W):
            c = checker if ((x // 12) + (y // 12)) % 2 else bg
            i = (y * W + x) * 4
            canvas[i], canvas[i + 1], canvas[i + 2], canvas[i + 3] = c[0], c[1], c[2], 255
    for idx, p in enumerate(paths):
        r = load(p)
        if r is None:
            continue
        sw, sh, spx = r
        scale = min((cell - 8) / float(sw), (cell - 8) / float(sh))
        tw, th = max(1, int(sw * scale)), max(1, int(sh * scale))
        ox = (idx % cols) * cell + (cell - tw) // 2
        oy = (idx // cols) * cell + (cell - th) // 2
        for ty in range(th):
            sy = int(ty / scale)
            for tx in range(tw):
                sx = int(tx / scale)
                si = (sy * sw + sx) * 4
                a = spx[si + 3] / 255.0
                if a <= 0.004:
                    continue
                di = ((oy + ty) * W + ox + tx) * 4
                for ch in range(3):
                    canvas[di + ch] = int(spx[si + ch] * a + canvas[di + ch] * (1 - a))
                canvas[di + 3] = 255
    write_rgba(out, W, H, canvas)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=CHAR_DIR)
    ap.add_argument("--compare", default="", help="旧版目录，逐张对比")
    ap.add_argument("--sheet", default="", help="另存一张总览图")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    if not files:
        sys.exit("目录里没有 PNG：%s" % args.dir)

    report = {}
    print("%-34s %9s %5s %5s %6s %6s %5s  %s"
          % ("文件", "尺寸", "覆盖%", "软边%", "碎块", "红像素", "顶边", "构图"))
    for f in files:
        p = os.path.join(args.dir, f)
        r = load(p)
        if r is None:
            print("%-34s  读不出" % f)
            continue
        w, h, px = r
        m = analyse(w, h, px)
        report[f[:-4]] = m
        ok = "OK" if m["edge"]["top"] <= 20 and m["edge"]["left"] <= 80 and m["edge"]["right"] <= 80 else "!! 出画"
        print("%-34s %9s %5.1f %5.1f %6d %6d %5d  %s"
              % (f[:-4], m["size"], m["coverage"], m["soft_pct"],
                 m["blobs"], m["red"], m["edge"]["top"], ok))

    if args.compare:
        print("\n=== 与旧版对比（红像素 = 红绳有没有画出来；碎块 = 漂浮色块）===")
        print("%-34s %-22s %-22s" % ("文件", "旧: 红像素/碎块/软边%", "新: 红像素/碎块/软边%"))
        for f in files:
            new = report.get(f[:-4])
            op = os.path.join(args.compare, f)
            if new is None or not os.path.exists(op):
                continue
            ro = load(op)
            if ro is None:
                continue
            wo, ho, pxo = ro
            mo = analyse(wo, ho, pxo)
            print("%-34s %-22s %-22s" % (f[:-4],
                  "%d / %d / %.1f" % (mo["red"], mo["blobs"], mo["soft_pct"]),
                  "%d / %d / %.1f" % (new["red"], new["blobs"], new["soft_pct"])))

    if args.sheet:
        out = args.sheet if os.path.isabs(args.sheet) else os.path.join(ROOT, args.sheet)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        sheet([os.path.join(args.dir, f) for f in files], out)
        print("\n总览图 -> %s（顺序：%s）" % (os.path.relpath(out, ROOT), ", ".join(f[:-4] for f in files)))

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
