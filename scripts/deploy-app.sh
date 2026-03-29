#!/usr/bin/env bash
# 构建 Release 版 Sleepless.app 并部署到系统「应用程序」文件夹（默认 /Applications）
# 用法: scripts/deploy-app.sh
# 可选环境变量 SLEEPLESS_DEPLOY_TARGET：覆盖目标目录（例如仅测试时用 $HOME/Applications）
set -euo pipefail

readonly DEFAULT_DEPLOY_TARGET="/Applications"
readonly APP_BUNDLE_NAME="Sleepless.app"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_TARGET="${SLEEPLESS_DEPLOY_TARGET:-$DEFAULT_DEPLOY_TARGET}"
SRC_APP="$ROOT/build/$APP_BUNDLE_NAME"
DEST_APP="$DEPLOY_TARGET/$APP_BUNDLE_NAME"

cd "$ROOT"

# 先打 Release 包，保证部署的是发布构建
bash "$ROOT/scripts/build-app.sh" release

if [[ ! -d "$SRC_APP" ]]; then
	echo "错误: 未找到构建产物 $SRC_APP" >&2
	exit 1
fi

if [[ ! -d "$DEPLOY_TARGET" ]]; then
	echo "错误: 目标目录不存在: $DEPLOY_TARGET" >&2
	exit 1
fi

# 用 ditto 复制 .app，保留资源分叉与权限（优于裸 cp -R）
rm -rf "$DEST_APP"
ditto "$SRC_APP" "$DEST_APP"

echo "已部署: $DEST_APP"
