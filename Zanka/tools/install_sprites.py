#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 BiRefNet 抠好的立绘收尾并实装进 assets/char/。

为什么还需要这一步
------------------
BiRefNet 输出的是**原尺寸画布**（512x512），背景变透明但人物在画框里的
大小和位置是 SD 随机决定的。而游戏里 char_layer.gd 是按「半身像填满画框」
摆放的（sprite_h = 屏幕高 x 0.80，KEEP_ASPECT_CENTERED），
不裁边的话 13 个角色会一大一小、位置也歪。

所以这里做两件事（顺序不能换）：
  1. ``clean()``   —— 丢掉与主体不相连的孤立碎块（模型自己画的漂浮色块）
  2. ``autocrop()``—— 裁到内容包围盒 + 8px 边距，归一化各角色尺寸

这一步是幂等的：对同一张图重复裁边结果不变。

用法
----
    python3 tools/install_sprites.py                       # _matte -> assets/char
    python3 tools/install_sprites.py --dry-run              # 只看尺寸，不写盘
    python3 tools/install_sprites.py --indir X --outdir Y
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clean_sprites import read_rgba, write_rgba, clean, autocrop  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_IN = os.path.join(ROOT, "tools/_matte")
DEFAULT_OUT = os.path.join(ROOT, "assets/char")
SUFFIX = "_cutout"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--indir", default=DEFAULT_IN)
    ap.add_argument("--outdir", default=DEFAULT_OUT)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.indir) if f.endswith(SUFFIX + ".png"))
    if not files:
        sys.exit("没有 %s*.png：%s" % (SUFFIX, args.indir))
    if not args.dry_run:
        os.makedirs(args.outdir, exist_ok=True)

    print("%-34s %-13s %-13s %s" % ("id", "抠图尺寸", "实装尺寸", "裁掉"))
    for f in files:
        sid = f[:-len(SUFFIX) - 4]
        r = read_rgba(os.path.join(args.indir, f))
        if r is None:
            print("%-34s  读不出" % sid)
            continue
        w, h, px = r
        _dropped, removed = clean(w, h, px)   # clean() 返回 (丢弃的连通域数, 丢弃的像素数)
        nw, nh, npx, _ = autocrop(w, h, px)
        dst = os.path.join(args.outdir, sid + ".png")
        if not args.dry_run:
            write_rgba(dst, nw, nh, npx)
        print("%-34s %-13s %-13s %s"
              % (sid, "%dx%d" % (w, h), "%dx%d" % (nw, nh),
                 "碎块 %d px%s" % (removed, "" if args.dry_run else "  -> " + os.path.relpath(dst, ROOT))))
    if args.dry_run:
        print("\n（dry-run，未写盘）")
    else:
        print("\n实装完成。接着跑：python3 tools/check_sprites.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
