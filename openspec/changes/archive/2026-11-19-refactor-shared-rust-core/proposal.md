# Proposal

## Why

`totp-core` 的行为有两份各自演进的实现：Swift（`MacOS/Sources/TOTPCore/`，约 306 行）和 Kotlin（`Android/core/`，约 232 行）。两份都对着 `openspec/specs/totp-core/spec.md` 写，但已经分化出可见差异：账户名展示规则不同（macOS 只按冒号拆，Android 还按空格拆并对重复账号去重），备份只共享「每行一条 URI」这层文本约定。算法或解析的每次改动都要改两处、跑两套测试，且两端结果是否一致没有机制保证。把纯计算与协议层收敛到一份 Rust 实现，经 UniFFI 生成 Swift/Kotlin 绑定，让 `totp-core` 的规则只有一份可执行实现。

## What Changes

- 新增仓库根 `core/` Rust crate（`totp-core`）：Base32 编解码、HOTP/TOTP（单次与批量）、`otpauth://` 解析与生成、展示名称规范化、密钥校验、备份序列化。用 UniFFI proc-macro 导出，不维护 `.udl`。
- 新增构建流水线：`core/scripts/build-macos.sh` 产出静态库 + Swift 绑定并打包 `TOTPCoreFFI.xcframework`；`core/scripts/build-android.sh` 用 `cargo-ndk` 产出 `arm64-v8a` `.so` + Kotlin 绑定。产物不入库，由脚本生成。
- macOS：`MacOS/Sources/TOTPCore/` 瘦身为 Keychain 存储与剪贴板；算法、解析、备份、展示拆分全部改调绑定；`MacOS/run.sh` 在 `swift build` 前先构建 core。
- Android：`Android/core` 从 `org.jetbrains.kotlin.jvm` 模块改为承载 UniFFI Kotlin 绑定的 Android 库模块（jniLibs + JNA）；`Home.kt`、`AccountStore.kt`、`SettingsScreen.kt` 改用绑定模型与批量接口。
- **BREAKING** 备份格式从「UTF-8 文本，每行一条 `otpauth://totp` URI」改为 JSON 备份文档。1.0 导出的 `.txt` 备份在 2.0 中不再被接受，导入会明确报「格式不是 JSON 备份」。
- **BREAKING** 版本号升到 `2.0.0`：根 `README.md`、`MacOS/Sources/TOTPApp/Preferences.swift` 的 `version`（设置页显示 `v2.0.0`）、Android `versionName`/`versionCode`、`run.sh` 生成的 `Info.plist`。
- 账户名展示规则统一为「首个冒号优先，否则首个空格；重复账号只留一份」，两端一致（macOS 侧标题会出现可见变化）。

## Capabilities

### New Capabilities

无。共享核心是既有 `totp-core` 的实现方式变更，不新开能力；`openspec/config.yaml` 也要求变更归入 `specs/totp-core/`、`specs/macos/`、`specs/android/` 之一。

### Modified Capabilities

- `totp-core`：密钥跨共享核心边界必须以字节传递且不得可打印；新增展示名称规范化的唯一规则；新增 JSON 备份文档的结构与导入拒绝规则。
- `macos/backup-export`：导出产物从「每行一条 URI 的文本」改为 JSON 备份文档。
- `android/settings`：导出与导入改为 JSON 备份文档；导入拒绝 1.0 的行文本，并保留保存/跳过计数。
- `macos/app-settings`：设置页显示的版本号从 `v1.0.0` 改为 `v2.0.0`。

## Impact

- 代码：新增 `core/`（Cargo crate + 两个构建脚本）；改动 `MacOS/Package.swift`、`MacOS/Sources/TOTPCore/*`、`MacOS/Tests/TOTPCoreTests/*`、`MacOS/run.sh`、`Android/core/*`、`Android/app/build.gradle.kts`、`Android/app/src/main/kotlin/app/totp/{Home,AccountStore,SettingsScreen}.kt`、根 `README.md`、`.gitignore`。
- 工具链：新增 Rust 工具链、`aarch64-apple-darwin`/`x86_64-apple-darwin` 与两个 Android target、Android NDK（r28+）、`cargo-ndk`。本机当前都没有，开发机需要约 1–2 GB 下载。
- 测试：29 个 JVM 单测里的算法向量迁到 `cargo test`；`:core` 变成 Android 模块后 JVM 单测不能再跑向量，JNI 绑定由一条真机仪器测试冒烟。
- 体积：本机实测 core 的 macOS `.dylib` 为 318 KB（LTO + strip）；Android 预计每 ABI 增加 200–500 KB，另加 `jna.aar` 约 200 KB。
- 性能：本机实测单次 HOTP（SHA-1，8 字节消息）Rust 0.27 µs，对比 macOS CryptoKit 1.9 µs、Android JVM `Mac.getInstance` 0.46 µs；跨边界开销手写 JNI 空调用 3–7 ns、`.dylib` 调用与静态链接无差异。端到端不可感知。
- 数据：1.0 的 `.txt` 备份在 2.0 不可导入，需要单独的升级说明（README「从 1.0 升级」）。
