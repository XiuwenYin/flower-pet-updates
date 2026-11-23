#!/bin/sh
# 瓶中花 Mac 一行安装：curl -fsSL <更新源>/install.sh | sh
# 用 curl 下载的文件不带"来自网络"的标记，打开时不会被系统拦下，不用去隐私与安全性里点"仍要打开"。
# 依次试每个更新源（国内镜像、GitHub），安装包下载完核对 sha256。
set -e
FEEDS='[{"url":"https://yqkjtech.com/flower/","bin":true},{"url":"https://xiuwenyin.github.io/flower-pet-updates/","bin":false}]'
GITHUB='XiuwenYin/flower-pet-updates'
APP='瓶中花.app'
DIR=${DESKKIT_INSTALL_DIR:-/Applications}
# 系统语言是中文时提示用中文，其余用英文
case "$(defaults read -g AppleLanguages 2>/dev/null | sed -n 2p)${LANG}" in *zh*) ZH=1 ;; *) ZH= ;; esac
say() { if [ -n "$ZH" ]; then echo "$1"; else echo "$2"; fi; }
case "$(uname -m)" in arm64) KEY=darwin-arm64 ;; *) KEY=darwin-x64 ;; esac
URLS=$(echo "$FEEDS" | tr '{},' '\n\n\n' | sed -n 's/.*"url": *"\([^"]*\)".*/\1/p')
BINS=$(echo "$FEEDS" | tr '{}' '\n\n' | grep '"bin": *true' | sed -n 's/.*"url": *"\([^"]*\)".*/\1/p')
LINE=
for F in $URLS; do
  LINE=$(curl -fsSL --max-time 15 "${F}installers.txt?t=$(date +%s)" 2>/dev/null | grep "^$KEY " | head -1) && [ -n "$LINE" ] && break
done
[ -n "$LINE" ] || { say "没有找到安装包" "No installer found"; exit 1; }
VER=$(echo "$LINE" | cut -d' ' -f2); NAME=$(echo "$LINE" | cut -d' ' -f3); SHA=$(echo "$LINE" | cut -d' ' -f4)
TMP=$(mktemp -d)
trap 'hdiutil detach "$TMP/mnt" -quiet 2>/dev/null; rm -rf "$TMP"' EXIT
say "正在下载 $NAME" "Downloading $NAME"
OK=
for U in $(for B in $BINS; do echo "${B}releases/v$VER/$NAME"; done) "https://github.com/$GITHUB/releases/download/v$VER/$NAME"; do
  if curl -fL --progress-bar --speed-limit 20000 --speed-time 30 -o "$TMP/a.dmg" "$U" && [ "$(shasum -a 256 "$TMP/a.dmg" | cut -d' ' -f1)" = "$SHA" ]; then OK=1; break; fi
  say "换一个地址重试" "Trying another address"
done
[ -n "$OK" ] || { say "安装包下载失败，请稍后重试" "Download failed. Try again later."; exit 1; }
hdiutil attach "$TMP/a.dmg" -nobrowse -readonly -mountpoint "$TMP/mnt" -quiet
[ -z "$DESKKIT_INSTALL_DIR" ] && osascript -e "quit app \"${APP%.app}\"" 2>/dev/null || true
sleep 1
rm -rf "$DIR/$APP"
ditto "$TMP/mnt/$APP" "$DIR/$APP"
xattr -dr com.apple.quarantine "$DIR/$APP" 2>/dev/null || true
[ -z "$DESKKIT_INSTALL_DIR" ] && open "$DIR/$APP"
say "瓶中花已安装" "Flowers in a Vase installed"
