#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""切断「细通道」式的抠图漏洞。

症状：人物浅色衣服上出现大块透明洞（换底色能直接透过去），但洞口与画面边缘
      其实是连通的——背景靠一条很细的亮色通道钻进了衣服内部。
      因此普通「补洞」（只补封闭区域）不起作用。

做法（形态学开运算）：
  1. 取出背景掩膜（alpha 为透明的像素）；
  2. 对它做半径 r 的腐蚀 —— 细通道（宽度 < 2r）被切断；
  3. 只保留与画面边缘连通的部分；
  4. 再膨胀回去（限制在原来的背景掩膜内）；
  5. 得到的才是真正的背景，其余一律恢复不透明。

用法：
  python3 clean_corridors.py --dry-run
  python3 clean_corridors.py --r 2
"""
import argparse
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_sprites import read_rgba, write_rgba  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")


def _dilate(mask, w, h, r):
    """半径 r 的方形膨胀（可分离两趟）。"""
    tmp = bytearray(w * h)
    for y in range(h):
        row = y * w
        for x in range(w):
            hit = 0
            for k in range(-r, r + 1):
                xx = x + k
                if 0 <= xx < w and mask[row + xx]:
                    hit = 1
                    break
            tmp[row + x] = hit
    out = bytearray(w * h)
    for y in range(h):
        row = y * w
        for x in range(w):
            hit = 0
            for k in range(-r, r + 1):
                yy = y + k
                if 0 <= yy < h and tmp[yy * w + x]:
                    hit = 1
                    break
            out[row + x] = hit
    return out


def _erode(mask, w, h, r):
    """腐蚀 = 对补集做膨胀再取反。"""
    inv = bytearray(1 - v for v in mask)
    return bytearray(1 - v for v in _dilate(inv, w, h, r))


def clean_corridors(w, h, px, r=2, alpha_th=120):
    n = w * h
    bg = bytearray(1 if px[i * 4 + 3] <= alpha_th else 0 for i in range(n))

    er = _erode(bg, w, h, r)

    # 只保留与边缘连通的腐蚀后背景
    keep = bytearray(n)
    dq = deque()
    for x in range(w):
        for idx in (x, (h - 1) * w + x):
            if er[idx] and not keep[idx]:
                keep[idx] = 1
                dq.append(idx)
    for y in range(h):
        for idx in (y * w, y * w + w - 1):
            if er[idx] and not keep[idx]:
                keep[idx] = 1
                dq.append(idx)
    while dq:
        q = dq.popleft()
        x = q % w
        for t in ((q - 1 if x > 0 else -1),
                  (q + 1 if x < w - 1 else -1),
                  (q - w if q >= w else -1),
                  (q + w if q < n - w else -1)):
            if t >= 0 and er[t] and not keep[t]:
                keep[t] = 1
                dq.append(t)

    grown = _dilate(keep, w, h, r)
    final_bg = bytearray(grown[i] and bg[i] for i in range(n))

    changed = 0
    for i in range(n):
        want = 0 if final_bg[i] else 255
        if px[i * 4 + 3] != want:
            changed += 1
        px[i * 4 + 3] = want
    return sum(final_bg) * 100.0 / n, changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=CHAR_DIR)
    ap.add_argument("--r", type=int, default=2)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    print("%-34s %9s %9s" % ("文件", "背景占比", "改动像素"))
    for f in files:
        p = os.path.join(args.dir, f)
        r = read_rgba(p)
        if r is None:
            continue
        w, h, px = r
        ratio, changed = clean_corridors(w, h, px, args.r)
        if not args.dry_run and changed:
            write_rgba(p, w, h, px)
        print("%-34s %8.1f%% %9d" % (f[:-4], ratio, changed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
