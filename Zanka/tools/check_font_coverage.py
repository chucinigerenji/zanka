#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""检查文本用到的字，在子集化字体里到底有没有字形（**零依赖**）。

为什么必须查
------------
项目的中文字体是 `tools/make_font.py` **子集化**出来的：只收录「当时项目文本文件里
出现过的字」。所以**新写进代码的文案，只要有一个字不在子集里，真机上就渲染成豆腐块 □**。
这个坑踩过好几次：`✕`、`劝`、`叠`、`／`、`▶`、`备`、`或` 全都不在子集里。

实现
----
直接解析 TrueType/OpenType 的 `cmap` 表拿「覆盖的码点集合」，纯标准库。
**不依赖 Pillow** —— 本机 Pillow 已经装不回来了（Python 3.14 没有预编译 wheel，
源码编译也要工具链），而查字本来也不需要绘图库。

用法
----
    python3 tools/check_font_coverage.py scripts/ui/title_chara.gd
    python3 tools/check_font_coverage.py data/story/main.zs
    python3 tools/check_font_coverage.py --text "任意一句话"
    python3 tools/check_font_coverage.py --list-symbols    # 挑符号时先看哪些有字形
"""
import argparse
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = {
    "sans": os.path.join(ROOT, "assets/ui/ZankaSans.otf"),    # 全局默认字体（界面文字）
    "serif": os.path.join(ROOT, "assets/ui/ZankaSerif.otf"),  # 标题衬线体
}


# ------------------------------------------------------------------ cmap 解析

def _tables(d):
    n = struct.unpack(">H", d[4:6])[0]
    out = {}
    for i in range(n):
        off = 12 + i * 16
        out[d[off:off + 4]] = struct.unpack(">II", d[off + 8:off + 16])
    return out


def _fmt4(d, o):
    """cmap format 4：分段映射（CJK 子集最常见）。"""
    seg = struct.unpack(">H", d[o + 6:o + 8])[0] // 2
    ends = struct.unpack(">%dH" % seg, d[o + 14:o + 14 + seg * 2])
    starts = struct.unpack(">%dH" % seg, d[o + 16 + seg * 2:o + 16 + seg * 4])
    deltas = struct.unpack(">%dh" % seg, d[o + 16 + seg * 4:o + 16 + seg * 6])
    iro = o + 16 + seg * 6
    ranges = struct.unpack(">%dH" % seg, d[iro:iro + seg * 2])
    out = set()
    for i in range(seg):
        s, e = starts[i], ends[i]
        if s == 0xFFFF or e < s:
            continue
        for c in range(s, min(e, 0xFFFE) + 1):
            if ranges[i] == 0:
                g = (c + deltas[i]) & 0xFFFF
            else:
                p = iro + i * 2 + ranges[i] + (c - s) * 2
                if p + 2 > len(d):
                    continue
                g = struct.unpack(">H", d[p:p + 2])[0]
                if g:
                    g = (g + deltas[i]) & 0xFFFF
            if g:
                out.add(c)
    return out


def _fmt12(d, o):
    """cmap format 12：连续区间（4 字节码点）。"""
    n = struct.unpack(">I", d[o + 12:o + 16])[0]
    out = set()
    for i in range(n):
        s, e, g = struct.unpack(">III", d[o + 16 + i * 12:o + 28 + i * 12])
        if e - s > 0x10000:        # 防呆：子集字体不该有超大区间
            continue
        for c in range(s, e + 1):
            if g + (c - s):
                out.add(c)
    return out


def covered(path):
    d = open(path, "rb").read()
    t = _tables(d)
    if b"cmap" not in t:
        raise RuntimeError("字体里没有 cmap 表：%s" % path)
    coff = t[b"cmap"][0]
    n = struct.unpack(">H", d[coff + 2:coff + 4])[0]
    out = set()
    for i in range(n):
        base = coff + 4 + i * 8
        so = coff + struct.unpack(">I", d[base + 4:base + 8])[0]
        fmt = struct.unpack(">H", d[so:so + 2])[0]
        if fmt == 4:
            out |= _fmt4(d, so)
        elif fmt == 12:
            out |= _fmt12(d, so)
    return out


# ------------------------------------------------------------------ 取待查文本

def _gd_strings(src):
    """提取 GDScript 源码里的双引号字符串（跳过 # 注释）。

    做词法扫描而不是正则：正则会把注释里出现的 ASCII 双引号当成字符串起点，
    从而把注释内容误报成缺字（踩过）。
    """
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


def gather(paths, text):
    out = text
    for p in paths:
        with open(p, encoding="utf-8") as fh:
            src = fh.read()
        if p.endswith(".gd"):
            out += " ".join(_gd_strings(src))
        else:
            for line in src.split("\n"):
                st = line.strip()
                if st.startswith("#") or st.startswith("//"):
                    continue
                out += line + "\n"
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*", help="要检查的文本文件")
    ap.add_argument("--text", default="")
    ap.add_argument("--font", default="sans", choices=list(FONTS))
    ap.add_argument("--list-symbols", action="store_true",
                    help="列出常用符号哪些有字形（写 UI 挑符号前先看）")
    args = ap.parse_args()

    cov = covered(FONTS[args.font])

    if args.list_symbols:
        syms = "▼▲◀▶●○◆◇■□★☆·…×—〜「」『』【】（）〈〉《》※✓✕→←↑↓"
        print("字体 %s：共 %d 个字形" % (args.font, len(cov)))
        for c in syms:
            print("  %s   U+%04X   %s" % (c, ord(c), "有" if ord(c) in cov else "**没有**"))
        return 0

    text = gather(args.paths, args.text)
    if not text.strip():
        sys.exit("没有要检查的内容（给文件路径或 --text）")

    chars = sorted({c for c in text if ord(c) > 0x7F})
    bad = [c for c in chars if ord(c) not in cov]
    print("字体 %s：共 %d 个字形；本次检查 %d 个非 ASCII 字符"
          % (args.font, len(cov), len(chars)))
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
