#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按住「平坦度」抠图 —— 一次解决渐变背景 / 多色背景 / 白衣白底。

之前用的判据是「颜色和背景参考色够不够接近」，于是：
  * 背景有渐变   -> 边缘那圈超出容差，被留下
  * 背景分两块色 -> 只认了主流那块，另一块整条留在图上
  * 白衣 vs 白底 -> 容差一放宽就把衣服一起吃穿

新判据不看绝对颜色，只看**局部平坦度**：
  背景（无论什么颜色、有没有渐变）总是平坦的；
  人物一定有线稿，轮廓处必然是色阶突变。
所以「从画面边缘出发，沿着平坦像素泛滥，撞到线条就停」——
既不会因为渐变而漏抠，也不会顺着白衣服爬进去（衣服和背景之间隔着线稿）。

用法：
  python3 flat_cutout.py --dry-run
  python3 flat_cutout.py                  # 写回
  python3 flat_cutout.py --grad 20 --rad 1
"""
import argparse
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_sprites import read_rgba, write_rgba, clean, autocrop  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")


def flat_cutout(w, h, px, grad_t=20, rad=1, alpha_th=120, feather=True):
    """返回 (背景占比, 改动像素数)。"""
    n = w * h
    lum = [0.0] * n
    for i in range(n):
        o = i * 4
        lum[i] = 0.299 * px[o] + 0.587 * px[o + 1] + 0.114 * px[o + 2]

    # 局部梯度：平坦处接近 0，线稿处很大
    flat = bytearray(n)
    for y in range(h):
        row = y * w
        for x in range(w):
            i = row + x
            g = 0.0
            if x >= rad and x < w - rad:
                g += abs(lum[i + rad] - lum[i - rad])
            if y >= rad and y < h - rad:
                g += abs(lum[i + rad * w] - lum[i - rad * w])
            if g < grad_t:
                flat[i] = 1

    # 从四边沿平坦像素泛滥（8 邻域，避免被细线缝隙卡住）
    bg = bytearray(n)
    dq = deque()
    for x in range(w):
        for idx in (x, (h - 1) * w + x):
            if flat[idx] and not bg[idx]:
                bg[idx] = 1
                dq.append(idx)
    for y in range(h):
        for idx in (y * w, y * w + w - 1):
            if flat[idx] and not bg[idx]:
                bg[idx] = 1
                dq.append(idx)
    while dq:
        q = dq.popleft()
        x = q % w
        y = q // w
        x0, x1 = max(0, x - 1), min(w - 1, x + 1)
        y0, y1 = max(0, y - 1), min(h - 1, y + 1)
        for yy in range(y0, y1 + 1):
            base = yy * w
            for xx in range(x0, x1 + 1):
                t = base + xx
                if flat[t] and not bg[t]:
                    bg[t] = 1
                    dq.append(t)

    changed = 0
    for i in range(n):
        want = 0 if bg[i] else 255
        if px[i * 4 + 3] != want:
            changed += 1
        px[i * 4 + 3] = want
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
    return sum(bg) * 100.0 / n, changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=CHAR_DIR)
    ap.add_argument("--grad", type=float, default=20.0, help="平坦度阈值，越大越激进")
    ap.add_argument("--rad", type=int, default=1)
    ap.add_argument("--no-crop", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    print("%-34s %9s %9s  %s" % ("文件", "背景占比", "改动像素", "尺寸"))
    for f in files:
        p = os.path.join(args.dir, f)
        r = read_rgba(p)
        if r is None:
            continue
        w, h, px = r
        ratio, changed = flat_cutout(w, h, px, args.grad, args.rad)
        warning = ""
        if ratio < 15:
            warning = "!! 抠得太狠"
        elif ratio > 90:
            warning = "!! 几乎没抠掉"
        if not args.no_crop:
            clean(w, h, px)
            nw, nh, npx, _ = autocrop(w, h, px)
        else:
            nw, nh, npx = w, h, px
        if not args.dry_run and not warning:
            write_rgba(p, nw, nh, npx)
        print("%-34s %8.1f%% %9d  %dx%d %s"
              % (f[:-4], ratio, changed, nw, nh, warning or ("dry-run" if args.dry_run else "")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
