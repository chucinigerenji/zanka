#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""立绘 alpha 重建流水线（可反复跑，幂等）。

为什么需要单独一个脚本：
  alpha 处理分了四五步，每步都会改 alpha。手动一步步跑很容易漏掉某步、
  或者顺序搞错（顺序错了会互相破坏）。这里把顺序固定下来，RGB 每步都保留，
  所以随时可以整条重跑。

流水线（顺序不能换）：
  1. cutout_rgb        —— 从 RGB 重新抠：四边中位数当参考色 + 边界洪水填充
  2. clean_corridors   —— 形态学开运算切断细通道（修「浅色衣服被抠出洞」）
  3. strip_clean       —— 清掉贴着左/上/右边缘的均匀色带
                          （**不处理下边缘**：立绘本来就在腰部裁断，底部必须是实心的）
  4. erode_alpha       —— 轮廓收缩，削掉背景色和人物色混合出来的灰色抗锯齿晕
  5. clean + autocrop  —— 清孤立碎块 + 裁到内容包围盒，归一化各张的角色尺寸

用法：
  python3 rebuild_sprites.py --dry-run
  python3 rebuild_sprites.py
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_sprites import read_rgba, write_rgba, clean, autocrop, erode_alpha  # noqa: E402
import gen_assets          # noqa: E402
import clean_corridors     # noqa: E402
import importlib           # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")


def strip_clean_ltr(w, h, px, tol=26, max_frac=0.2, alpha_th=120):
    """只清左/上/右三条边的均匀色带，**跳过下边缘**。"""
    n = w * h
    bg = bytearray(n)
    maxw = int(w * max_frac)
    maxh = int(h * max_frac)

    def close(i, j):
        o1, o2 = i * 4, j * 4
        return (abs(px[o1] - px[o2]) + abs(px[o1 + 1] - px[o2 + 1])
                + abs(px[o1 + 2] - px[o2 + 2])) < tol * 3

    for y in range(h):
        row = y * w
        for x in range(1, maxw):
            if not close(row + x, row):
                break
            bg[row + x] = 1
        for x in range(1, maxw):
            if not close(row + w - 1 - x, row + w - 1):
                break
            bg[row + w - 1 - x] = 1
    for x in range(w):
        for y in range(1, maxh):          # 只走上边
            if not close(y * w + x, x):
                break
            bg[y * w + x] = 1

    removed = 0
    for i in range(n):
        if bg[i] and px[i * 4 + 3] > alpha_th:
            px[i * 4 + 3] = 0
            removed += 1
    return removed


def rebuild(path, corridor_r=2, erode_r=2, dry=False):
    r = read_rgba(path)
    if r is None:
        return None
    w, h, px = r
    rgb = bytearray(w * h * 3)
    for i in range(w * h):
        rgb[i * 3] = px[i * 4]
        rgb[i * 3 + 1] = px[i * 4 + 1]
        rgb[i * 3 + 2] = px[i * 4 + 2]

    res, ratio = gen_assets.cutout_rgb(bytes(rgb), w, h)
    if res is None:
        return {"id": os.path.basename(path)[:-4], "err": "抠图失败 %.1f%%" % (ratio * 100)}
    out = bytearray(res)

    ratio2, _ = clean_corridors.clean_corridors(w, h, out, corridor_r) if corridor_r else (0, 0)
    stripped = strip_clean_ltr(w, h, out)
    eroded = erode_alpha(w, h, out, erode_r) if erode_r else 0
    clean(w, h, out)
    nw, nh, npx, _ = autocrop(w, h, out)
    if not dry:
        write_rgba(path, nw, nh, npx)
    return {"id": os.path.basename(path)[:-4], "bg": ratio2, "strip": stripped,
            "erode": eroded, "size": (nw, nh)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=CHAR_DIR)
    ap.add_argument("--corridor", type=int, default=2)
    ap.add_argument("--erode", type=int, default=2)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    print("%-34s %8s %8s %8s  %s" % ("文件", "背景%", "边带", "削边", "尺寸"))
    for f in files:
        info = rebuild(os.path.join(args.dir, f), args.corridor, args.erode, args.dry_run)
        if info is None:
            continue
        if "err" in info:
            print("%-34s  !! %s" % (info["id"], info["err"]))
            continue
        print("%-34s %7.1f%% %8d %8d  %dx%d"
              % (info["id"], info["bg"], info["strip"], info["erode"],
                 info["size"][0], info["size"][1]))
    print("完成%s" % ("（dry-run）" if args.dry_run else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
