# Design

## Context

`Android/` 只有占位 README。算法、URI 和 Base32 的行为以 `openspec/specs/totp-core/spec.md` 为准，本变更不改那份规格。macOS 已用同一 URI 文本做备份（每行一条 `otpauth://totp`）。

## Goals / Non-Goals

**Goals:**

- 一个可安装的离线 Android 应用，验证码与 macOS 对同一密钥、同一时刻一致。
- `core` 不依赖 Android，JUnit 在 JVM 上跑 RFC 向量。
- 密钥离开内存前先加密；界面不能被最近任务或录屏截到验证码。

**Non-Goals:**

- 手动录入表单、CSV 导入、网络同步、Wear / 桌面小部件。
- 修改 `totp-core` 或 macOS 规格与代码。
- 申请 `INTERNET` 或存储读写权限。

## Decisions

1. **两个 Gradle 模块。** `:core` 是纯 Kotlin JVM 库：HOTP/TOTP、Base32、otpauth 解析与序列化。`:app` 依赖它，放 Compose、CameraX、ML Kit、Room、Tink。算法测试只打在 `:core`，避免仪器测试才能跑向量。
   备选：单模块。拒绝，因为 Android 依赖会拖进单元测试。

2. **算法直接按 `totp-core` 实现，不引入 OTP 库。** RFC 4226 动态截断 + HMAC-SHA1/256/512，计数器为 `floor(unixTime / period)`。拒绝的输入抛受检错误，不返回部分结果。
   备选：`dev.turingcomplete:kotlin-onetimepassword`。拒绝，多一个依赖，而且测试向量仍然要自己写。

3. **密钥：Android Keystore 中的 AES-256 主密钥包一层 Tink `AesGcmKey`（`AES256_GCM`），密文与账户 id 一起放进 Room。** 元数据表只有 id、站点、用户名、算法、位数、周期、排序，没有 secret 列。读账户时解密；解密失败的行跳过，与规格一致。
   备选：`EncryptedSharedPreferences`（占位 README 写过）。拒绝，账户列表需要排序和按 id 更新，Room 更合适；Tink 是用户指定的加密原语。

4. **扫码用捆绑模型 `com.google.mlkit:barcode-scanning`，不使用 Play Services 的可选模块下载。** 相册走 `ActivityResultContracts.PickVisualMedia`，`InputImage.fromFilePath` 交给同一个扫描器。识别到的字符串只交给 `core` 的解析器；解析失败不入库。
   相机权限被拒时只停相机，相册入口仍在。

5. **`FLAG_SECURE` 设在 Activity 窗口上**，列表、扫码、设置共用这一个 Activity，避免漏一个界面。

6. **剪贴板清空用主线程延时 30 秒，清空前读回剪贴板，只有内容仍是当时复制的验证码才清。** 开关默认开，存在 DataStore。分段显示只影响文本排版，复制始终是纯数字。

7. **备份格式与 macOS 相同：** UTF-8，一行一条 URI，字段含 secret、algorithm、digits、period。导入逐行解析，坏行计入跳过数，不中断其余行。

## Risks / Trade-offs

- [ML Kit 捆绑模型增大 APK] → 接受。联网下载模型会要求网络，和零网络冲突。
- [Keystore 在部分设备上会在锁屏后拒绝解密] → 解密失败时跳过该账户并给出可读错误，不崩溃、不写空密钥。
- [相册选图在旧系统上行为不同] → `minSdk` 定为 26，照片选择器使用 AndroidX 回溯实现，仍不申请存储权限。
- [`FLAG_SECURE` 也挡住用户自己的截图] → 接受，这是规格要求。

## Migration Plan

全新应用，无旧数据可迁。回滚就是不安装。与 macOS 的互通只靠用户手动导入导出的文本文件。

## Open Questions

无。`minSdk` 26 和单 Activity 不影响规格，实现时按此执行即可。
