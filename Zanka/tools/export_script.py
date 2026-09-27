#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 .zs 剧本导出成人类可读的 Markdown，方便脱离 Godot 通读/审稿。

输出：<项目根>/../残夏_剧本全文.md
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data/story/main.zs")
OUT = os.path.join(os.path.dirname(ROOT), "残夏_剧本全文.md")
CHAR_DB = os.path.join(ROOT, "scripts/core/char_db.gd")

# 需要在正文里显式标注出来的系统触发点
CALLOUT = {
    "letter": "✉ 进入【信件系统】",
    "care": "📋 进入【照护日志】",
    "timeslot": "🕒 进入【时间编排】",
    "ending": "★ 触发结局",
}


def load_names():
    src = io.open(CHAR_DB, encoding="utf-8").read()
    m = re.search(r"const NAMES\s*:=\s*\{(.*?)\n\}", src, re.S)
    names = {}
    if m:
        for k, v in re.findall(r'"([^"]*)"\s*:\s*"([^"]*)"', m.group(1)):
            names[k] = v
    return names


def main():
    if not os.path.exists(SRC):
        print("!! 找不到 %s" % SRC)
        return 1
    names = load_names()
    lines = io.open(SRC, encoding="utf-8").read().split("\n")

    out = ["# 《残夏 -The Last Tide-》剧本全文",
           "",
           "> 由 `tools/export_script.py` 从 `data/story/main.zs` 自动生成，请勿手改。",
           "> 这是游戏里实际会显示的文本（含分支与五个结局）。",
           ""]
    stat = {"say": 0, "narr": 0, "labels": 0, "choices": 0}

    for raw in lines:
        line = raw.rstrip()
        s = line.strip()
        if not s or s.startswith("#") or s.startswith("//"):
            continue
        if s.startswith("::"):
            stat["labels"] += 1
            out.append("")
            out.append("---")
            out.append("")
            out.append("### `%s`" % s[2:].strip())
            out.append("")
            continue
        if s.startswith("@"):
            sp = s.find(" ")
            cmd = s[1:sp] if sp > 0 else s[1:]
            arg = s[sp + 1:].strip() if sp > 0 else ""
            if cmd == "chapter":
                out.append("")
                out.append("## %s" % arg)
                out.append("")
            elif cmd == "cal":
                out.append("")
                out.append("> **【%s】**" % arg.replace(" ", "　"))
                out.append("")
            elif cmd in CALLOUT:
                out.append("")
                out.append("> %s　`%s`" % (CALLOUT[cmd], arg))
                out.append("")
            elif cmd == "choice":
                out.append("")
                out.append("**── 选择 ──**")
                out.append("")
            elif cmd == "endchoice":
                out.append("")
            elif cmd == "ending":
                out.append("")
                out.append("> ★ 结局 `%s`" % arg)
                out.append("")
            continue
        if s.startswith("*"):
            stat["choices"] += 1
            body = s[1:].strip()
            if "->" in body:
                text, target = body.split("->", 1)
                out.append("- 【%s】　→ `%s`" % (text.strip(), target.split("|")[0].strip()))
            else:
                out.append("- 【%s】" % body)
            continue
        if "|" in s:
            spk, text = s.split("|", 1)
            spk = spk.strip()
            text = text.strip()
            if spk:
                stat["say"] += 1
                nm = names.get(spk, spk)
                out.append("")
                out.append("**%s**：%s" % (nm, text) if nm else text)
            else:
                stat["narr"] += 1
                out.append("")
                out.append("*%s*" % text)
            continue

    io.open(OUT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("已导出 -> %s" % OUT)
    print("   台词 %d 条 / 旁白 %d 条 / 选项 %d 个 / 标签 %d 个"
          % (stat["say"], stat["narr"], stat["choices"], stat["labels"]))
    print("   %.1f KB" % (os.path.getsize(OUT) / 1024.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
