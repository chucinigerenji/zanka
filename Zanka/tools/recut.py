#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""重抠一遍立绘（不需要重新出图）。

背景：SD 常常画的不是纯色底，而是带轻微渐变的背板。
「全局参考色 + 固定容差」的抠法对付不了渐变——渐变边缘会超出容差，
于是贴边的一圈被吃掉了，中间却留下一大块背景。

这里换成**邻域自适应区域生长**：
  * 从四边出发做 BFS；
  * 一个像素能被接受，要同时满足两个条件：
      1) 与「已经接受的邻居」颜色差 < local_tol   —— 这样能顺着渐变一路走
      2) 与「全局背景参考色」颜色差 < global_tol —— 防止顺着软边一路爬进人物
  * 人物的勾线是色阶断崖，条件 1 会立刻挡住。

关键点：透明像素里仍保留着原始 RGB，所以这一步可以反复跑、随时调整参数。

用法：
  python3 recut.py --dry-run            # 只看会清掉多少
  python3 recut.py                      # 写回
  python3 recut.py --local 10 --global 80
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_sprites import read_rgba, write_rgba  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")


def recut(w, h, px, local_tol=13, global_tol=95, feather=True):
    n = w * h
    stride = w * 4

    # 背景参考色 = 四边像素中位数
    samples = []
    for x in range(0, w, 2):
        samples.append(px[x * 4:x * 4 + 3])
        samples.append(px[((h - 1) * w + x) * 4:((h - 1) * w + x) * 4 + 3])
    for y in range(0, h, 2):
        samples.append(px[(y * w) * 4:(y * w) * 4 + 3])
        samples.append(px[(y * w + w - 1) * 4:(y * w + w - 1) * 4 + 3])
    if not samples:
        return None
    mid = len(samples) // 2
    rr = sorted(s[0] for s in samples)[mid]
    rg = sorted(s[1] for s in samples)[mid]
    rb = sorted(s[2] for s in samples)[mid]

    def d2(i, r, g, b):
        o = i * 4
        dr = px[o] - r
        dg = px[o + 1] - g
        db = px[o + 2] - b
        return dr * dr + dg * dg + db * db

    lt2 = local_tol * local_tol
    gt2 = global_tol * global_tol

    visited = bytearray(n)
    stack = []
    # 种子：四边上与参考色接近的像素
    for x in range(w):
        for idx in (x, (h - 1) * w + x):
            if not visited[idx] and d2(idx, rr, rg, rb) < 60 * 60:
                visited[idx] = 1
                stack.append(idx)
    for y in range(h):
        for idx in (y * w, y * w + w - 1):
            if not visited[idx] and d2(idx, rr, rg, rb) < 60 * 60:
                visited[idx] = 1
                stack.append(idx)

    while stack:
        p = stack.pop()
        x = p % w
        pr, pg, pb = px[p * 4], px[p * 4 + 1], px[p * 4 + 2]
        for q in ((p - 1 if x > 0 else -1),
                  (p + 1 if x < w - 1 else -1),
                  (p - w if p >= w else -1),
                  (p + w if p < n - w else -1)):
            if q < 0 or visited[q]:
                continue
            if d2(q, pr, pg, pb) < lt2 and d2(q, rr, rg, rb) < gt2:
                visited[q] = 1
                stack.append(q)

    bg = sum(visited)
    # 写回 alpha（半透明像素保留原 RGB，只是不再可见）
    for i in range(n):
        px[i * 4 + 3] = 0 if visited[i] else 255
    if feather:
        for y in range(h):
            base = y * w
            for x in range(w):
                i = base + x
                if not px[i * 4 + 3]:
                    continue
                if ((x > 0 and not px[(i - 1) * 4 + 3]) or
                        (x < w - 1 and not px[(i + 1) * 4 + 3]) or
                        (y > 0 and not px[(i - w) * 4 + 3]) or
                        (y < h - 1 and not px[(i + w) * 4 + 3])):
                    px[i * 4 + 3] = 150
    return bg * 100.0 / n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=CHAR_DIR)
    ap.add_argument("--local", type=int, default=13)
    ap.add_argument("--global", dest="gtol", type=int, default=95)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    print("%-34s %8s   %s" % ("文件", "背景占比", "说明"))
    for f in files:
        p = os.path.join(args.dir, f)
        r = read_rgba(p)
        if r is None:
            print("%-34s   跳过（非 RGBA）" % f)
            continue
        w, h, px = r
        ratio = recut(w, h, px, args.local, args.gtol)
        if ratio is None:
            print("%-34s   失败" % f)
            continue
        note = ""
        if ratio < 20:
            note = "!! 背景占比过低，可能啃到人物"
        elif ratio > 88:
            note = "!! 背景占比过高，可能没抠干净"
        if not args.dry_run and not note:
            write_rgba(p, w, h, px)
        print("%-34s %7.1f%%   %s" % (f[:-4], ratio, note or ("dry-run" if args.dry_run else "已写回")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
