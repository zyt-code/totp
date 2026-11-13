# TOTP (v1.0.0)

跨平台 TOTP（时间型一次性密码）认证器。已完整支持 macOS 菜单栏客户端及 Android 应用。

## 目录结构

```
MacOS/     macOS 14+ 菜单栏应用（Swift / SwiftUI）
Android/   Android 客户端（Kotlin / Jetpack Compose）
openspec/  双端规格根目录
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
- 离线优先：无后端，Secret 安全存储（macOS Keychain / Android 存储）。

## 构建与运行

### macOS
```bash
cd MacOS
./run.sh                    # 调试构建
./run.sh --release --install # 发布构建
```

### Android
使用标准 Android Studio 环境打开 `Android/` 目录进行构建。

## 环境要求

- macOS 14+ / Swift 5.10+
- Android SDK 34+ / JDK 17+
