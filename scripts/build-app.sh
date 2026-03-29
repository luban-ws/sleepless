#!/usr/bin/env bash
# SwiftPM 构建可执行文件并组装 Sleepless.app（CLI / CI 友好）
# 用法: scripts/build-app.sh [debug|release]
set -euo pipefail

CONFIG_RAW="${1:-debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$CONFIG_RAW" == "release" ]]; then
	SWIFT_CONFIG="release"
else
	SWIFT_CONFIG="debug"
fi

bash "$ROOT/scripts/make-app-icon.sh"

swift build -c "$SWIFT_CONFIG" --product Sleepless
BIN="$(swift build -c "$SWIFT_CONFIG" --show-bin-path)/Sleepless"
APP_NAME="Sleepless.app"
DEST_DIR="$ROOT/build"
APP_PATH="$DEST_DIR/$APP_NAME"

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
cp "$BIN" "$APP_PATH/Contents/MacOS/Sleepless"
chmod +x "$APP_PATH/Contents/MacOS/Sleepless"

cp "$ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
mkdir -p "$APP_PATH/Contents/Resources"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
	cp "$ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
fi

printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null || true

echo "已组装: $APP_PATH"
