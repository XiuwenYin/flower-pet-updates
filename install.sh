#!/bin/sh
# 瓶中花 Mac 一行安装：curl -fsSL https://xiuwenyin.github.io/flower-pet-updates/install.sh | sh
# 用 curl 下载的文件不带"来自网络"的标记，打开时不会被系统拦下，不用去隐私与安全性里点"仍要打开"
set -e
FEED=https://xiuwenyin.github.io/flower-pet-updates
DIR=${FLOWER_INSTALL_DIR:-/Applications}
case "$(uname -m)" in arm64) KEY=darwin-arm64 ;; *) KEY=darwin-x64 ;; esac
URL=$(curl -fsSL "$FEED/manifest.json?t=$(date +%s)" | tr ',{}' '\n\n\n' | grep "\"$KEY\"" | sed 's/.*: *"\(.*\)".*/\1/')
case "$URL" in https://github.com/XiuwenYin/flower-pet-updates/releases/download/*) ;; *) echo "没有找到安装包"; exit 1 ;; esac
TMP=$(mktemp -d)
trap 'hdiutil detach "$TMP/mnt" -quiet 2>/dev/null; rm -rf "$TMP"' EXIT
echo "正在下载 $(basename "$URL")"
curl -fL --progress-bar -o "$TMP/a.dmg" "$URL"
hdiutil attach "$TMP/a.dmg" -nobrowse -readonly -mountpoint "$TMP/mnt" -quiet
[ -z "$FLOWER_INSTALL_DIR" ] && osascript -e 'quit app "瓶中花"' 2>/dev/null || true
sleep 1
rm -rf "$DIR/瓶中花.app"
ditto "$TMP/mnt/瓶中花.app" "$DIR/瓶中花.app"
xattr -dr com.apple.quarantine "$DIR/瓶中花.app" 2>/dev/null || true
[ -z "$FLOWER_INSTALL_DIR" ] && open "$DIR/瓶中花.app"
echo "瓶中花已安装"
