#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 .zs 剧本打包成 Godot 能识别为资源的 JSON。

为什么需要这一步：
  Godot 导出项目时，**非资源文件默认不会被打进包里**。`.zs` 没有对应的
  ResourceFormatLoader，所以 APK 里不会有它，游戏一运行就会「剧本文件不存在」。
  而 `.json` 是 Godot 能识别的资源类型，一定会被导出。

因此约定：
  * data/story/main.zs    —— 唯一的**编辑源**，人写这个
  * data/story/main.json  —— 由本脚本生成，游戏运行时优先读它

改完剧本后必须重跑本脚本。tools/validate.py 会校验两者是否同步。
"""
import hashlib
import io
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data/story/main.zs")
DST = os.path.join(ROOT, "data/story/main.json")


def main():
    if not os.path.exists(SRC):
        print("!! 找不到 %s" % SRC)
        return 1
    text = io.open(SRC, encoding="utf-8").read()
    payload = {
        "_comment": "由 tools/pack_story.py 从 main.zs 生成，请勿手改。改完 main.zs 后重跑该脚本。",
        "source": "data/story/main.zs",
        "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
        "lines": text.count("\n") + 1,
        "text": text,
    }
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    with io.open(DST, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print("已打包 -> %s" % os.path.relpath(DST, ROOT))
    print("   源 %d 行 / %d 字符，sha256=%s..." % (payload["lines"], len(text), payload["sha256"][:12]))
    print("   输出 %.1f KB" % (os.path.getsize(DST) / 1024.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
