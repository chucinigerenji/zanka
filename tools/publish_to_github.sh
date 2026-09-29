#!/usr/bin/env bash
# 把《残夏》工程推送到 GitHub，并把打包好的手机版 / 电脑版上传为 Release 资源。
#
# 为什么分两步：GitHub 限制**单个文件 100MB 不能进 git 仓库**，
# 而 Windows 版 exe 有 103MB —— 所以源码走 git push，
# 二进制产物走 Release（Release 单个资源上限 2GB）。
#
# 用法（在仓库根目录执行）：
#   GH_TOKEN=ghp_xxx GH_OWNER=你的用户名 GH_REPO=zanka bash tools/publish_to_github.sh
#
# 可选：
#   GH_REPO       仓库名，默认 zanka
#   GH_TAG        版本 tag，默认 v0.1.0
#   GH_VISIBILITY public | private，默认 public
#   GH_NAME/GH_EMAIL  仓库的提交者身份（默认沿用当前 git 配置）
set -euo pipefail

: "${GH_TOKEN:?必须提供 GH_TOKEN（GitHub Personal Access Token）}"
: "${GH_OWNER:?必须提供 GH_OWNER（你的 GitHub 用户名）}"
REPO="${GH_REPO:-zanka}"
TAG="${GH_TAG:-v0.1.0}"
VIS="${GH_VISIBILITY:-public}"
API="https://api.github.com"
AUTH=(-H "Authorization: Bearer ${GH_TOKEN}" -H "Accept: application/vnd.github+json")

cd "$(dirname "$0")/../.."          # 切到仓库根目录（含 .git 的那一层）
[ -d .git ] || { echo "这里不是 git 仓库根目录" >&2; exit 1; }

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

say "1/4 创建（或复用）仓库 $GH_OWNER/$REPO（$VIS）"
code=$(curl -s -o /tmp/gh_repo.json -w '%{http_code}' -X POST "${AUTH[@]}" \
  "$API/user/repos" -d "{\"name\":\"$REPO\",\"private\":$([ "$VIS" = private ] && echo true || echo false),\"description\":\"残夏 -The Last Tide- ｜ Godot 4.7 中文视觉小说\"}")
case "$code" in
  201) echo "已创建 ✓" ;;
  422) echo "仓库已存在，复用 ✓" ;;
  *)   echo "创建失败（HTTP $code）："; cat /tmp/gh_repo.json; exit 1 ;;
esac

say "2/4 推送源码（分支 $(git branch --show-current)）"
[ -n "${GH_NAME:-}" ]  && git config user.name  "$GH_NAME"
[ -n "${GH_EMAIL:-}" ] && git config user.email "$GH_EMAIL"
git remote remove origin 2>/dev/null || true
# 注意：token 会写进 .git/config。用完记得改回不带 token 的地址，或在 GitHub 后台吊销 token。
git remote add origin "https://${GH_OWNER}:${GH_TOKEN}@github.com/${GH_OWNER}/${REPO}.git"
git push -u origin HEAD

say "3/4 创建 Release $TAG"
code=$(curl -s -o /tmp/gh_rel.json -w '%{http_code}' -X POST "${AUTH[@]}" \
  "$API/repos/${GH_OWNER}/${REPO}/releases" \
  -d "$(python3 - "$TAG" <<'PY'
import json,sys
tag=sys.argv[1]
print(json.dumps({
  "tag_name": tag,
  "name": f"残夏 -The Last Tide- {tag}",
  "body": ("首个可玩版本。\n\n"
           "**Android**：`残夏-Android-arm64-v0.1.0.apk`（arm64-v8a，Android 6.0+）\n\n"
           "**Windows**：`残夏-Windows-x86_64-v0.1.0.zip`，解压后双击 exe，"
           "**请保持 exe 与 pck 在同一文件夹**。\n\n"
           "读法：点点屏幕推进，偶尔选一次。标题画面右侧的立绘可以点不同部位。\n"
           "共 5 个结局，分支由第五章末的一句话决定。"),
  "draft": False,
  "prerelease": False,
}, ensure_ascii=False))
PY
)")
if [ "$code" = "201" ]; then
  REL_ID=$(python3 -c "import json;print(json.load(open('/tmp/gh_rel.json'))['id'])")
  echo "Release 已创建（id=$REL_ID）✓"
else
  echo "创建 Release 失败（HTTP $code）："; cat /tmp/gh_rel.json; exit 1
fi

say "4/4 上传产物"
UP="https://uploads.github.com/repos/${GH_OWNER}/${REPO}/releases/${REL_ID}/assets"
shopt -s nullglob
for f in release/*; do
  name=$(basename "$f")
  echo "  上传 $name（$(du -h "$f" | cut -f1)）…"
  curl -s -o /tmp/gh_up.json -w '    HTTP %{http_code}\n' -X POST \
    -H "Authorization: Bearer ${GH_TOKEN}" -H "Content-Type: application/octet-stream" \
    --data-binary @"$f" "$UP?name=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$name")"
  python3 -c "
import json
d=json.load(open('/tmp/gh_up.json'))
print('    ->', d.get('browser_download_url') or d.get('message'))
" 2>/dev/null || true
done

say "完成"
echo "仓库：https://github.com/${GH_OWNER}/${REPO}"
echo "发布：https://github.com/${GH_OWNER}/${REPO}/releases/tag/${TAG}"
echo
echo "⚠ 提醒：token 已写入 .git/config，建议用完后在 GitHub 后台吊销它，"
echo "   并执行：git remote set-url origin https://github.com/${GH_OWNER}/${REPO}.git"
