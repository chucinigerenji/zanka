#!/usr/bin/env bash
# 一键导出《残夏》的全部产物：安卓 APK + Windows + Linux
#
# 用法：
#   cd Zanka
#   bash tools/export_all.sh
#
# 需要：Godot 4.7.2（标准版，非 mono）+ 版本严格对应的导出模板。
#   Godot 可执行文件不在 PATH 里时，用环境变量指定：
#     GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64 bash tools/export_all.sh
#
# 安卓导出还需要 Java SDK 17 + Android SDK（Build-Tools 与 Platform），
# 并在 Godot「编辑器设置 → 导出 → Android」里填好路径与 debug keystore；
# 导出 Windows / Linux 不需要任何 SDK。
#
# 预设名必须与 export_presets.cfg 里的一致（Android / Windows Desktop / Linux/X11）。

set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."          # 切到工程根目录（Zanka/）
mkdir -p build

if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
  echo "找不到 Godot 可执行文件：$GODOT" >&2
  echo "请用 GODOT=/路径/到/godot 指定。" >&2
  exit 1
fi

echo "==> 使用的 Godot：$("$GODOT" --version 2>/dev/null || echo "$GODOT")"
echo "    （版本必须是 4.7.2，否则导出模板不匹配）"
echo

echo "==> [1/4] 导入资源（首次会生成 .godot/，这一步同时会真正编译所有 GDScript）"
"$GODOT" --headless --path . --import
echo

echo "==> [2/4] 导出安卓 APK（arm64-v8a）"
"$GODOT" --headless --path . --export-release "Android" "build/Zanka.apk"
ls -la build/Zanka.apk
echo

echo "==> [3/4] 导出 Windows（单文件 .exe，PCK 已内嵌）"
"$GODOT" --headless --path . --export-release "Windows Desktop" "build/Zanka.exe"
ls -la build/Zanka.exe
echo

echo "==> [4/4] 导出 Linux（单文件）"
"$GODOT" --headless --path . --export-release "Linux/X11" "build/Zanka.x86_64"
chmod +x build/Zanka.x86_64
ls -la build/Zanka.x86_64
echo

echo "全部完成，产物在 build/："
ls -la build/
