# Android

Kotlin + Jetpack Compose 的离线 TOTP 客户端。算法、Base32、`otpauth://totp/` 解析与备份序列化在仓库根 `core/`（Rust），经 UniFFI 生成 Kotlin 绑定到 `:core` 模块；与 `openspec/specs/totp-core` 一致，不另写一套规则。

## 权限与安全

- 危险权限只有 `CAMERA`；另有普通权限 `VIBRATE`（扫码成功反馈）。不声明 `INTERNET`、`ACCESS_NETWORK_STATE`，也不申请存储读写权限。
- 密钥用 Android Keystore 主密钥和 Tink `AES256_GCM` 加密后写进 Room 的 `secrets` 表。`accounts` 表只有元数据，没有密钥列。
- 窗口设置 `FLAG_SECURE`，最近任务预览和录屏看不到验证码。
- 云备份与设备迁移排除了数据库和偏好，避免密钥被备份带走。

## 添加账户

没有手动填写表单。用相机实时扫码，或用系统照片选择器从相册选一张图。只接受 `totp-core` 判定合法的 `otpauth://totp/`。

## 备份

导出为 JSON 文档（`format=totp-backup`、`version=2`），和 macOS 端的格式相同，可以互相导入。导入会逐条校验，坏账户跳过并计数；1.0 的「每行一条 URI」文本文件会被拒绝并提示期望的格式。

## 构建与测试

先构建核心产物（`.so` 与 Kotlin 绑定不入库）：

```bash
core/scripts/build-android.sh
```

然后：

```bash
cd Android
./gradlew :app:assembleDebug                  # 产物 app/build/outputs/apk/debug/
./gradlew :app:lintDebug                      # 静态检查
./gradlew :app:connectedDebugAndroidTest      # 需要设备或模拟器
```

算法向量、URI 解析、备份往返的单元测试在 Rust 侧，随核心一起跑：

```bash
cd core && cargo test
```

需要本机 Android SDK（`compileSdk` 37，`minSdk` 26）、JDK 21+、NDK r28 以上和 `cargo-ndk`。`:core` 现在是 Android library（承载 jniLibs 与 JNA 绑定），它的测试只能在真机/模拟器上跑；JVM 单元测试已随算法一起迁到 Rust。`AccountStoreTest`（Keystore 加密往返、配对与删除）在 `app/src/androidTest`，属于仪器测试。
