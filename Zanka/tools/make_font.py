#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把系统 CJK 字体子集化成项目字体。

为什么不直接把 32MB 的 NotoSansCJK-Regular.ttc 塞进项目：
  * Godot 导入会再复制一份到 .godot/，项目体积直接翻倍
  * 手机上首次打开编辑器、首次运行都要吃这份开销

子集化范围 = 项目里所有文本文件出现过的字符（剧本 + JSON + GDScript 里的 UI 文案）
  + ASCII 可见字符 + 常用中英标点 + 保险用的一批高频字。
这样既不会缺字，体积又能降到几百 KB。
"""
import io
import os
import sys

from fontTools.ttLib import TTCollection
from fontTools import subset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_SANS = os.path.join(ROOT, "assets/ui/ZankaSans.otf")
OUT_SERIF = os.path.join(ROOT, "assets/ui/ZankaSerif.otf")
SYS_SANS = "/system/fonts/NotoSansCJK-Regular.ttc"
SYS_SERIF = "/system/fonts/NotoSerifCJK-Regular.ttc"

# 保险字表：即使将来补写台词也不至于立刻缺字
SAFETY = (
    "的一是了我不人在他有这个上们来到时大地为子中你说生国年着就那和要她出也得里后自以会家可下而过天去能对小多然于心学么之都好看起发当没成只如事把还用第样道想作种开美总从无情己面最女但现前些所同日手又行意动方期它头经长儿回位分爱老因很给名法间斯知世什两次使身者被高已亲其进此话常与活正感"
    "残夏汐浦町冈田三浦栞佐野瞳富美千鹤大贯浜口源治诚桐生正人晓早见长谷部店雨潮祭台風号诊所医院走廊学教室防波堤沉船満月烟火蝉蜕信封信纸照护日志时段编排回忆点碎片周目结局存档读取设置鉴赏"
    "春夏秋冬晨昼夜朝夕黄昏深夜清晨上午下午分钟秒年月日星期一二三四五六七八九十百千万亿零两"
)

TEXT_EXTS = (".gd", ".zs", ".json", ".tscn", ".godot", ".md", ".cfg", ".txt")


def collect_chars():
    chars = set()
    for dirpath, dirnames, files in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".godot", ".git")]
        for f in files:
            if not f.endswith(TEXT_EXTS):
                continue
            p = os.path.join(dirpath, f)
            try:
                with io.open(p, encoding="utf-8", errors="ignore") as fh:
                    chars |= set(fh.read())
            except Exception as e:
                print("  跳过 %s：%s" % (f, e))
    # ASCII 可见 + 常用标点
    chars |= set(chr(c) for c in range(0x20, 0x7F))
    chars |= set("　、。〈〉《》「」『』【】〔〕・ー—…‥“”‘’·×÷°±※→←↑↓■□●○◆◇★☆♪♭♯")
    chars |= set(SAFETY)
    chars.discard("\n")
    chars.discard("\r")
    chars.discard("\t")
    return chars


def pick_face(path, want=("SC", "Simplified")):
    ttc = TTCollection(path, lazy=True)
    faces = []
    for i, f in enumerate(ttc.fonts):
        try:
            full = f["name"].getDebugName(4) or f["name"].getDebugName(1) or ""
        except Exception:
            full = ""
        faces.append((i, full))
    print("  %s 内含 %d 个 face：" % (os.path.basename(path), len(faces)))
    for i, n in faces:
        print("     [%d] %s" % (i, n))
    for i, n in faces:
        if any(w in n for w in want):
            return i, ttc, faces
    return 0, ttc, faces


def build(src, dst, chars, label):
    if not os.path.exists(src):
        print("!! 找不到系统字体 %s" % src)
        return False
    idx, ttc, faces = pick_face(src)
    font = ttc.fonts[idx]
    print("  使用 face [%d] %s" % (idx, faces[idx][1]))
    text = "".join(sorted(chars))
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.name_legacy = True
    opts.notdef_outline = True
    opts.recalc_bounds = True
    opts.drop_tables += ["DSIG"]
    opts.desubroutinize = False
    ss = subset.Subsetter(options=opts)
    ss.populate(text=text)
    ss.subset(font)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    font.flavor = None
    font.save(dst)
    print("  %s -> %s (%.1f KB, %d 字符)" % (label, os.path.relpath(dst, ROOT),
                                             os.path.getsize(dst) / 1024.0, len(chars)))
    return True


def main():
    chars = collect_chars()
    print("收集到 %d 个不同字符" % len(chars))
    ok1 = build(SYS_SANS, OUT_SANS, chars, "Noto Sans CJK SC")
    ok2 = build(SYS_SERIF, OUT_SERIF, chars, "Noto Serif CJK SC")
    if not (ok1 and ok2):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
