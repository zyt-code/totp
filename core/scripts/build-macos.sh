#!/bin/bash
set -euo pipefail

# 编译 Rust core 并组装 macOS 侧产物：xcframework（C 头 + modulemap + 静态库）与 Swift 绑定。
# 产物不入库，由本脚本生成；MacOS/run.sh 会在 swift build 前调用它。

cd "$(dirname "$0")/.."
CORE_DIR="$PWD"
REPO_DIR="$(cd .. && pwd)"
MACOS_DIR="$REPO_DIR/MacOS"
BINDINGS_DIR="$MACOS_DIR/Sources/TOTPCoreBindings"
FRAMEWORK_DIR="$MACOS_DIR/Frameworks/TOTPCoreFFI.xcframework"
LIB_DIR_NAME="macos-arm64_x86_64"
HEADERS_DIR="$FRAMEWORK_DIR/$LIB_DIR_NAME/Headers"
SIZE_LIMIT=1048576

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "缺少 $1：$2" >&2
        exit 1
    }
}

need cargo "安装 rustup：https://rustup.rs"
need rustup "安装 rustup：https://rustup.rs"
need lipo "安装 Xcode 命令行工具：xcode-select --install"
need plutil "安装 Xcode 命令行工具：xcode-select --install"

TARGETS=(aarch64-apple-darwin x86_64-apple-darwin)
INSTALLED="$(rustup target list --installed)"
for target in "${TARGETS[@]}"; do
    if ! grep -qx "$target" <<<"$INSTALLED"; then
        echo "缺少 Rust target ${target}：rustup target add $target" >&2
        exit 1
    fi
done

echo "==> 编译 Rust core（${TARGETS[*]}）"
for target in "${TARGETS[@]}"; do
    cargo build --release --lib --target "$target"
done

echo "==> 合并静态库"
mkdir -p target/universal
lipo -create -output target/universal/libtotp_core.a \
    "target/aarch64-apple-darwin/release/libtotp_core.a" \
    "target/x86_64-apple-darwin/release/libtotp_core.a"

echo "==> 编译宿主 uniffi-bindgen"
cargo build --release --bin uniffi-bindgen
test -x target/release/uniffi-bindgen

echo "==> 生成 Swift 绑定"
rm -rf "$BINDINGS_DIR"
mkdir -p "$BINDINGS_DIR"
./target/release/uniffi-bindgen generate \
    --library target/aarch64-apple-darwin/release/libtotp_core.dylib \
    --language swift \
    --out-dir "$BINDINGS_DIR"

echo "==> 组装 xcframework"
rm -rf "$FRAMEWORK_DIR"
mkdir -p "$HEADERS_DIR"
cp target/universal/libtotp_core.a "$FRAMEWORK_DIR/$LIB_DIR_NAME/libtotp_core.a"
# C 头与 modulemap 属于 xcframework 的 C 模块，不留在 Swift 源码目录
cp "$BINDINGS_DIR/totp_coreFFI.h" "$HEADERS_DIR/totp_coreFFI.h"
cp "$BINDINGS_DIR/totp_coreFFI.modulemap" "$HEADERS_DIR/module.modulemap"
rm -f "$BINDINGS_DIR/totp_coreFFI.h" "$BINDINGS_DIR/totp_coreFFI.modulemap"

cat > "$FRAMEWORK_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>macos-arm64_x86_64</string>
            <key>LibraryPath</key>
            <string>libtotp_core.a</string>
            <key>HeadersPath</key>
            <string>Headers</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>macos</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
PLIST

plutil -lint "$FRAMEWORK_DIR/Info.plist" >/dev/null

echo "==> 校验产物"
lipo -info target/universal/libtotp_core.a
# 静态库只参与链接、不单独发布；用 dylib 衡量代码体积（超限即失败）
DYLIB_SIZE="$(stat -f%z target/aarch64-apple-darwin/release/libtotp_core.dylib)"
echo "    dylib: ${DYLIB_SIZE} 字节（预算 ${SIZE_LIMIT}）"
if [ "$DYLIB_SIZE" -gt "$SIZE_LIMIT" ]; then
    echo "超出体积预算：${DYLIB_SIZE} > ${SIZE_LIMIT}" >&2
    exit 1
fi
test -f "$BINDINGS_DIR/totp_core.swift"
echo "==> 完成：$FRAMEWORK_DIR"
