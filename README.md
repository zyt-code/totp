# TOTP (v2.0.1)

跨平台 TOTP（时间型一次性密码）认证器。macOS 菜单栏客户端与 Android 应用共用同一份 Rust 核心：算法、Base32、`otpauth://` 解析和备份序列化只有一份实现。

## 目录结构

```
core/     共享 Rust 核心（totp-core），经 UniFFI 生成 Swift / Kotlin 绑定
MacOS/    macOS 14+ 菜单栏应用（Swift / SwiftUI）
Android/  Android 客户端（Kotlin / Jetpack Compose）
openspec/ 双端规格根目录
```

## 功能

### macOS
- 常驻菜单栏，点击状态项弹出账户列表；单击复制验证码，支持自动清空剪贴板。
- 支持手动录入、粘贴 `otpauth://` 及屏幕二维码识别。
- 设置：剪贴板自动清理、验证码格式定制、数据导出备份。

### Android
- 完整支持 OTP 账户的导入、生成及管理。
- 遵循 Material 3 设计规范，支持主流安卓设备。

### 通用
- 支持 SHA-1 / SHA-256 / SHA-512，6 位或 8 位长度，自定义刷新周期。
- 离线优先：无后端，Secret 安全存储（macOS Keychain / Android Keystore 加密）。
- 备份为 JSON 文档（`format=totp-backup`、`version=2`），两端互相可导入。

## 构建前置

- macOS 14+ / Swift 5.10+ / Xcode 命令行工具
- Rust 工具链（`rustup`）与目标：
  ```bash
  rustup target add aarch64-apple-darwin x86_64-apple-darwin aarch64-linux-android
  cargo install cargo-ndk
  ```
- Android：Android SDK 37 / JDK 21+ / **NDK r28 以上**（`ANDROID_HOME`，或 `ANDROID_NDK_HOME` 直接指向 NDK）

核心产物不入库，由脚本生成（首次编译需要几分钟，之后增量）：

```bash
core/scripts/build-macos.sh     # 通用静态库 + Swift 绑定 + TOTPCoreFFI.xcframework
core/scripts/build-android.sh   # arm64-v8a 的 libtotp_core.so + Kotlin 绑定
```

两个脚本都会自检依赖（缺什么会直接报缺哪个命令 / target）、校验产物体积（单架构 ≤ 1 MB），Android 脚本还校验 `.so` 的 16 KB 页对齐。

## 构建与运行

### macOS

```bash
cd MacOS
./run.sh                      # 自动先构建 core，再调试构建并启动
./run.sh --release --install  # 发布构建并安装到 /Applications
```

### Android

用 Android Studio 打开 `Android/` 目录，或命令行：

```bash
core/scripts/build-android.sh
cd Android && ./gradlew :app:assembleDebug
```

## 从 1.0 升级

2.0 的备份是 JSON 文档，**不再接受** 1.0 的「UTF-8 文本、每行一条 `otpauth://totp` URI」文件；导入旧文件时会明确报「不是 2.0 的 JSON 备份」。

没有格式转换工具，所以升级前请先确认账户在 1.0 客户端里可读，升级后在 2.0 里重新导出一份备份。
