#!/bin/bash
set -euo pipefail

# 无论从哪里调用，都在脚本所在目录内工作
cd "$(dirname "$0")"

CONFIG="debug"
INSTALL=0
for arg in "$@"; do
    case "$arg" in
        --release) CONFIG="release" ;;
        --install) INSTALL=1 ;;
        *) echo "用法: ./run.sh [--release] [--install]"; exit 1 ;;
    esac
done

echo "==> 构建共享 Rust core..."
# 产物（xcframework + 生成的 Swift 绑定）不入库；工具链缺失时让脚本自己的报错原样透出。
../core/scripts/build-macos.sh

echo "==> 编译 TOTPApp（${CONFIG}）..."
swift build -c "$CONFIG" --product TOTPApp

APP_BUNDLE=".build/TOTPApp.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> 组装 App Bundle 结构..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp ".build/$CONFIG/TOTPApp" "$MACOS/TOTPApp"

if [ ! -f "Resources/AppIcon.icns" ]; then
    echo "==> 图标缺失，生成 AppIcon.icns..."
    swift scripts/generate_icon.swift
fi

# 图标必须在 codesign 之前就位，否则签名不会覆盖图标资源
cp "Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"

cat <<'PLIST' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>local.totp.TOTPApp</string>
    <key>CFBundleName</key>
    <string>TOTPApp</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>CFBundleExecutable</key>
    <string>TOTPApp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>用于扫描屏幕上的双重认证二维码</string>
</dict>
</plist>
PLIST

echo "==> 检查签名证书..."
CERT_NAME="LocalDev"
if codesign --force --deep --sign "${CERT_NAME}" "${APP_BUNDLE}" 2>/dev/null; then
    echo "找到证书: ${CERT_NAME}，执行固定身份签名成功！"
else
    echo "⚠️ 无法使用 ${CERT_NAME} 证书签名，降级为临时签名（ad-hoc）..."
    codesign --force --deep --sign - "${APP_BUNDLE}"
fi

TARGET="$APP_BUNDLE"
if [ "$INSTALL" -eq 1 ]; then
    DEST="/Applications/TOTPApp.app"
    echo "==> 安装到 ${DEST}..."
    rm -rf "$DEST"
    cp -R "$APP_BUNDLE" "$DEST"
    TARGET="$DEST"
fi

echo "==> 重启应用..."
pkill -x TOTPApp || true
# 等旧进程真正退出，否则 open 会撞上进程未释放的竞态（错误 -600）
while pgrep -x TOTPApp >/dev/null 2>&1; do sleep 0.1; done
open "$TARGET"

echo "==> 启动成功：${TARGET}"
