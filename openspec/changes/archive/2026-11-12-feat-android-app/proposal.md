# Proposal

## Why

仓库里的 Android 客户端还是空目录，账户无法在手机上离线使用，也不能和 macOS 端用同一份 `otpauth://` 备份互通。现在双端算法规则已经收在 `totp-core`，可以按同一套规则落地 Android，而不再复制一份算法规格。

## What Changes

- 在 `Android/` 新建 Kotlin + Jetpack Compose + Material 3 应用：动态取色、edge-to-edge、`FLAG_SECURE`。
- Manifest 只声明 `CAMERA`，不声明 `INTERNET`。
- 纯 Kotlin `core` 模块实现 `totp-core` 已有的 HOTP/TOTP、Base32 和 `otpauth://totp/` 解析与序列化，并用 JUnit 覆盖 RFC 测试向量。不修改 `totp-core` 的需求。
- 密钥用 Android Keystore + Google Tink `AES256_GCM` 加密后入库；账户元数据进 Room，且不含明文密钥。
- 添加入口只有相机实时扫码和相册选图，没有手动填写表单。扫码使用捆绑的 ML Kit 条码模型，相册使用系统照片选择器，不申请存储权限。
- 首页卡片列表支持复制、30 秒条件清剪贴板、长按重命名和删除。设置页提供自动清剪贴板、分段显示，以及与 macOS 互通的 `otpauth://` 文本导入导出。

## Capabilities

### New Capabilities

- `android/app-shell`: Compose 壳、Material 3、动态取色、edge-to-edge、`FLAG_SECURE`，以及 Manifest 只有 `CAMERA`、没有 `INTERNET`。
- `android/secure-storage`: Keystore + Tink `AES256_GCM` 保存密钥，Room 只保存不含密钥的元数据。
- `android/account-capture`: 相机扫码与相册选图，只接受 `totp-core` 判定合法的 `otpauth://totp/`。
- `android/account-list`: 首页卡片、环形倒计时、点击复制与 30 秒条件清空、长按重命名和删除。
- `android/settings`: 自动清剪贴板开关、分段显示开关、`otpauth://` 文本备份的导入和导出。

### Modified Capabilities

- 无。`totp-core` 与 `macos/*` 的需求不变。Android 引擎遵守现有 `totp-core`，不另写算法规则。

## Impact

- 新增 `Android/` Gradle 工程（`core` 纯 Kotlin 模块 + `app` Compose 模块）。现有 `Android/README.md` 占位说明会被实现取代。
- 新依赖：Jetpack Compose、Material 3、CameraX、`com.google.mlkit:barcode-scanning`（捆绑模型，不走 Play Services 下载）、Room、Google Tink、AndroidX Security / Keystore。
- 不改 `MacOS/` 代码，不改 `openspec/specs/totp-core/` 与 `openspec/specs/macos/`。
- 备份文本与 macOS 导出格式兼容：每行一条 `otpauth://totp` URI。
