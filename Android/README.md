# Android

Kotlin + Jetpack Compose 的离线 TOTP 客户端。算法、Base32 和 `otpauth://totp/` 解析在 `:core`，与 `openspec/specs/totp-core` 一致，不另写一套规则。

## 权限与安全

- 危险权限只有 `CAMERA`；另有普通权限 `VIBRATE`（扫码成功反馈）。不声明 `INTERNET`、`ACCESS_NETWORK_STATE`，也不申请存储读写权限。
- 密钥用 Android Keystore 主密钥和 Tink `AES256_GCM` 加密后写进 Room 的 `secrets` 表。`accounts` 表只有元数据，没有密钥列。
- 窗口设置 `FLAG_SECURE`，最近任务预览和录屏看不到验证码。
- 云备份与设备迁移排除了数据库和偏好，避免密钥被备份带走。

## 添加账户

没有手动填写表单。用相机实时扫码，或用系统照片选择器从相册选一张图。只接受 `totp-core` 判定合法的 `otpauth://totp/`。

## 备份

导出为 UTF-8 文本，一行一条 `otpauth://totp` URI，和 macOS 端的备份格式相同，可以互相导入。

## 构建与测试

```bash
cd Android
./gradlew :core:test :app:testDebugUnitTest   # 29 个 JVM 单元测试
./gradlew :app:assembleDebug                  # 产物 app/build/outputs/apk/debug/
./gradlew :app:lintDebug                      # 静态检查
./gradlew :app:connectedDebugAndroidTest      # 需要设备或模拟器
```

需要本机 Android SDK（`compileSdk` 37，`minSdk` 26）。`AccountStoreTest`（Keystore 加密往返、配对与删除）在 `app/src/androidTest`，属于仪器测试，需要设备或模拟器。

