#!/bin/bash
set -euo pipefail

# 编译 Android 侧产物：arm64-v8a 的 libtotp_core.so + Kotlin 绑定。
# 只打 arm64-v8a，与 Android/app/build.gradle.kts 的 abiFilters 一致。
# 产物不入库，由本脚本生成。

cd "$(dirname "$0")/.."
CORE_DIR="$PWD"
REPO_DIR="$(cd .. && pwd)"
ANDROID_CORE="$REPO_DIR/Android/core"
JNI_DIR="$ANDROID_CORE/src/main/jniLibs"
KOTLIN_DIR="$ANDROID_CORE/src/main/kotlin"
ABI="arm64-v8a"
SO="$JNI_DIR/$ABI/libtotp_core.so"
PAGE_16K=16384
SIZE_LIMIT=1048576

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "缺少 $1：$2" >&2
        exit 1
    }
}

need cargo "安装 rustup：https://rustup.rs"
need cargo-ndk "cargo install cargo-ndk"
need rustup "安装 rustup：https://rustup.rs"

if ! rustup target list --installed | grep -qx aarch64-linux-android; then
    echo "缺少 Rust target aarch64-linux-android：rustup target add aarch64-linux-android" >&2
    exit 1
fi

# cargo-ndk 需要 NDK 路径：ANDROID_NDK_HOME 直接指向 NDK 目录，否则在 SDK 下挑最新版本
NDK_HOME="${ANDROID_NDK_HOME:-}"
if [ -z "$NDK_HOME" ]; then
    NDK_HOME="$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/ndk/* 2>/dev/null | sort -V | tail -1 || true)"
fi
if [ -z "$NDK_HOME" ] || [ ! -f "$NDK_HOME/source.properties" ] || [ ! -d "$NDK_HOME/toolchains" ]; then
    echo "找不到可用的 Android NDK：${NDK_HOME:-未设置}（ANDROID_NDK_HOME 应指向 NDK 目录，或设置 ANDROID_HOME）" >&2
    exit 1
fi
export ANDROID_NDK_HOME="$NDK_HOME"
echo "==> 使用 NDK：$ANDROID_NDK_HOME"

echo "==> 编译 $ABI .so"
rm -rf "$JNI_DIR"
cargo ndk -t "$ABI" -o "$JNI_DIR" build --release --lib
test -f "$SO"

echo "==> 编译宿主库与 uniffi-bindgen"
cargo build --release --lib --bin uniffi-bindgen
test -x target/release/uniffi-bindgen
rm -rf "$KOTLIN_DIR/app/totp/core/ffi"
./target/release/uniffi-bindgen generate \
    --library target/release/libtotp_core.dylib \
    --language kotlin \
    --no-format \
    --out-dir "$KOTLIN_DIR"
test -f "$KOTLIN_DIR/app/totp/core/ffi/totp_core.kt"

echo "==> 校验 16 KB 页对齐与体积"
READELF="$(find "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt" -name llvm-readelf | head -1)"
if [ -z "$READELF" ]; then
    echo "找不到 llvm-readelf（NDK: ${ANDROID_NDK_HOME}）" >&2
    exit 1
fi
MIN_ALIGN=0
for align in $("$READELF" -l "$SO" | awk '/^[[:space:]]*LOAD/ {print $NF}'); do
    value=$((align))
    if [ "$value" -lt "$PAGE_16K" ]; then
        echo "LOAD 段对齐 $align 小于 16 KB，targetSdk 37 上会装不上" >&2
        exit 1
    fi
    [ "$value" -gt "$MIN_ALIGN" ] && MIN_ALIGN=$value
done
echo "    LOAD 段最小对齐：$MIN_ALIGN 字节"

SO_SIZE="$(stat -f%z "$SO")"
echo "    $ABI so：${SO_SIZE} 字节（预算 ${SIZE_LIMIT}）"
if [ "$SO_SIZE" -gt "$SIZE_LIMIT" ]; then
    echo "超出体积预算：${SO_SIZE} > ${SIZE_LIMIT}" >&2
    exit 1
fi
echo "==> 完成：$SO"
