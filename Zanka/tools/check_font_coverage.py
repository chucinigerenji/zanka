#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查文本用到的字，在子集化字体里到底有没有字形。

为什么必须查
------------
项目的中文字体是 `tools/make_font.py` **子集化**出来的：只收录「当时项目文本文件里
出现过的字」。所以**新写进代码的文案，只要有一个字不在子集里，真机上就渲染成豆腐块 □**。
这个坑已经踩过一次：弹窗右上角的 `✕`(U+2715) 没字形，实际显示是个空方框。

判定方法
--------
不做 cmap 解析，直接**渲染比对**：FreeType 遇到缺字会回退到 `.notdef`（一个方框），
所以拿一个几乎不可能出现在子集里的字（龘）当参照，逐字渲染成位图比字节。
位图完全一致 => 缺字。这比读表更贴近「真机上到底长什么样」。

用法
----
    python3 tools/check_font_coverage.py scripts/ui/title_chara.gd
    python3 tools/check_font_coverage.py --text "任意一句话"
    python3 tools/check_font_coverage.py --text "..." --font sans|serif
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = {
    "sans": os.path.join(ROOT, "assets/ui/ZankaSans.otf"),   # 全局默认字体（界面文字）
    "serif": os.path.join(ROOT, "assets/ui/ZankaSerif.otf"),  # 标题衬线体
}
NOTDEF_REF = "\u9f98"   # 龘：子集里几乎不可能有，用来取 .notdef 的位图
SIZE = 40
BOX = 64


def _gd_strings(src):
    """提取 GDScript 源码里的双引号字符串（跳过 # 注释）。"""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == "#":
            while i < n and src[i] != "\n":
                i += 1
        elif c == '"':
            i += 1
            buf = []
            while i < n and src[i] != '"':
                if src[i] == "\\" and i + 1 < n:
                    i += 1
                buf.append(src[i])
                i += 1
            i += 1
            out.append("".join(buf))
        else:
            i += 1
    return out


def sig(font, ch):
    img = Image.new("L", (BOX, BOX), 0)
    ImageDraw.Draw(img).text((4, 2), ch, font=font, fill=255)
    return img.tobytes()


def check(text, which="sans"):
    f = ImageFont.truetype(FONTS[which], SIZE)
    ref = sig(f, NOTDEF_REF)
    chars = sorted({c for c in text if ord(c) > 0x2000})   # 只看 CJK / 全角符号
    bad = [c for c in chars if sig(f, c) == ref]
    return chars, bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*", help="要检查的文本文件")
    ap.add_argument("--text", default="")
    ap.add_argument("--font", default="sans", choices=list(FONTS))
    args = ap.parse_args()

    text = args.text
    for p in args.paths:
        with open(p, encoding="utf-8") as fh:
            src = fh.read()
        if p.endswith(".gd"):
            # GDScript：只有双引号字符串里的字才会显示给玩家，注释里的字不渲染。
            # 这里做个小词法扫描而不是正则：正则会把注释里出现的 ASCII 双引号
            # 当成字符串起点，从而把注释内容误报成缺字（踩过）。
            text += " ".join(_gd_strings(src))
        else:
            for line in src.split("\n"):
                st = line.strip()
                if st.startswith("#") or st.startswith("//"):
                    continue
                text += line + "\n"

    if not text.strip():
        sys.exit("没有要检查的内容（给文件路径或 --text）")

    chars, bad = check(text, args.font)
    print("字体 %s：检查 %d 个不同汉字/全角符号" % (args.font, len(chars)))
    if not bad:
        print("全部有字形 ✓")
        return 0
    print("\n!! 以下 %d 个字没有字形，真机会显示成豆腐块 □：" % len(bad))
    print("   " + " ".join(bad))
    for c in bad:
        print("   U+%04X  %s" % (ord(c), c))
    return 1


if __name__ == "__main__":
    sys.exit(main())
