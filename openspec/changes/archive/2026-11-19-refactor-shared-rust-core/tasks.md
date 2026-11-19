# Tasks

## 1. Rust core：算法与协议

- [x] 1.1 建立 `core/` crate：`crate-type = ["staticlib", "cdylib"]`，依赖 `uniffi`/`hmac`/`sha1`/`sha2`/`url`/`percent-encoding`/`serde`/`serde_json`/`thiserror`，release profile 按 design 决定 12 配置；`lib.rs` 调 `uniffi::setup_scaffolding!()`，另加 `src/bin/uniffi-bindgen.rs`。验证：`cargo build --release` 与 `cargo run --bin uniffi-bindgen -- --help` 都成功，`Cargo.lock` 已提交。
- [x] 1.2 按 `openspec/specs/totp-core/spec.md` 既有的 HOTP、TOTP、Base32、密钥不进入文本四项要求实现 `base32.rs` 与 `otp.rs`（引用既有规则，不另写一套）。验证：`cargo test` 覆盖 RFC 4226 `755224`/`84755224`、RFC 6238 `94287082`/`68084774`、三算法、6/8 位、空密钥/负计数/非 6-8 位/非正周期各自拒绝，以及 `Debug` 输出不含密钥。
- [x] 1.3 实现 `otpauth.rs`：解析与生成，缺省 SHA-1/6/30，拒绝非 `otpauth://totp`、无 `secret`、非 SHA-1/256/512、非 6/8 位、period<1，保留 `+`→空格 的兼容处理（design 决定 11）。验证：`cargo test` 逐条迁入 `MacOS/Tests/TOTPCoreTests/OtpauthTests.swift` 与 `Android/core/src/test/kotlin/app/totp/core/OtpauthTest.kt` 的现有用例，并新增一条含 `+` 与中文 issuer 的向量。
- [x] 1.4 实现 `naming.rs`：冒号优先、否则首个空格、重复 token 折叠、账户名优先（`specs/totp-core` 的 Display name normalization 四条场景）。验证：`cargo test` 四条场景各一个用例全绿。
- [x] 1.5 实现 `backup.rs`：按 `specs/totp-core` 的 JSON backup document 导出与导入，未知 `format`/`version`、非 JSON、缺 `accounts` 一律整体失败，单账户非法计入 skip 并返回 `saved`/`skipped`。验证：`cargo test` 覆盖往返、`version: 1` 拒绝、行文本拒绝、单账户跳过四条场景。

## 2. 绑定与构建流水线

- [x] 2.1 `core/scripts/build-macos.sh`：两个 darwin target 编译静态库 → `lipo` → 生成 `MacOS/Frameworks/TOTPCoreFFI.xcframework`（C 头 + modulemap + `.a`），并用 `--library` 模式生成 Swift 绑定到 `MacOS/Sources/TOTPCoreFFI/`。验证：脚本连跑两次结果一致，`file`/`lipo -info` 显示含 arm64 与 x86_64 两个架构。
- [x] 2.2 `core/scripts/build-android.sh`：`cargo-ndk` 只编 `arm64-v8a`，`.so` 落 `Android/core/src/main/jniLibs/arm64-v8a/`，Kotlin 绑定落 `Android/core/src/main/kotlin/app/totp/core/ffi/`；脚本在缺 NDK/`cargo-ndk` 时打印缺项并以非零退出。验证：`llvm-readelf -l` 的 LOAD 段对齐 ≥ 2**14（16 KB），`nm -D` 能看到 UniFFI 导出符号。
- [x] 2.3 `.gitignore` 增加 `MacOS/Frameworks/`、`Android/core/src/main/jniLibs/`、`MacOS/Sources/TOTPCoreFFI/`、`Android/core/src/main/kotlin/app/totp/core/ffi/`。验证：构建后 `git status --porcelain` 不含这些路径。
- [x] 2.4 尺寸校验：脚本末尾断言单架构产物 ≤ 1 MB 并打印实际字节数。验证：故意超限时脚本非零退出，正常时打印尺寸。

## 3. macOS 集成

- [x] 3.1 `MacOS/Package.swift` 增加 `TOTPCoreFFI` binaryTarget 与绑定 source target 的链接配置。验证：`swift build` 通过，`import` 生成的类型可用。
- [x] 3.2 删除旧实现 `OTP.swift`、`Otpauth.swift`、`Secret.swift`、`Backup.swift`（`encodeBase32` 与 `decodeBase32` 分别在这两个文件里）与 `Account.swift` 里的 `displayParts`/`formattedCode` 展示逻辑，保留 `Storage.swift`、`Clipboard.swift`。验证：`grep -rn "func hotp\|func totp\|decodeBase32\|encodeBase32\|otpauthBackup" MacOS/Sources` 无残留，`swift build` 通过。
- [x] 3.3 `AccountList.swift` 的每秒刷新改成一次 `generate_codes_batch`；`SettingsView` 读取 core 的版本常量或改 `Preferences.version` 为 2.0.0 对应值。验证：`./run.sh` 后菜单栏列出账户，验证码与 `oathtool`/参考向量一致。
- [x] 3.4 测试迁移：删除 `TOTPTests`、`HOTPTests`、`Base32Tests`、`OtpauthTests`、`BackupTests`、`AccountTests`、`SecretTests`（已由 `cargo test` 承担），保留并适配 `StorageTests`、`SettingsTests`、`AccountManagementTests`，新增一条「同一密钥同一时刻与 Rust 向量一致」。验证：`swift test` 全绿。
- [x] 3.5 `MacOS/run.sh` 在 `swift build` 前调用 `core/scripts/build-macos.sh`（工具链缺失时原样透出脚本错误）。验证：删掉 `MacOS/Frameworks/` 后 `./run.sh` 从零跑通。

## 4. Android 集成

- [x] 4.1 `Android/core/build.gradle.kts` 改为 `com.android.library`：加 `jna` 依赖、`jniLibs` 打包、`kotlin` 配置；`Android/app/build.gradle.kts` 保持 `implementation(project(":core"))`。验证：`./gradlew :core:assembleDebug` 通过。
- [x] 4.2 删除 `Otp.kt`、`Otpauth.kt`、`Base32.kt`、`Naming.kt` 与 `Android/core/src/test/` 下已迁走的向量测试。验证：`grep -rn "HmacSHA\|fun hotp\|fun totp" Android --include=*.kt` 无残留，`:core:assembleDebug` 通过。
- [x] 4.3 `AccountStore.kt` 改用绑定模型（密钥仍由 Keystore + Tink 加密入库，`AccountParams.secret` 只以字节进出，不做 `==` 比较，按 design 决定 6）；`Home.kt` 用 `generate_codes_batch`；`SettingsScreen.kt` 的导入导出改成 JSON 并对 1.0 文本给出明确错误。验证：`./gradlew :app:assembleDebug` 与 `./gradlew :app:lintDebug` 通过。
- [x] 4.4 一条真机仪器测试：`System.loadLibrary` 生效、算一个已知向量的码、JSON 导出再导入往返。验证：`./gradlew :app:connectedDebugAndroidTest` 通过。

## 5. 版本与文档

- [x] 5.1 版本升 2.0.0：`README.md` 标题、`MacOS/Sources/TOTPApp/Preferences.swift` 的 `version`、`Android/app/build.gradle.kts`（`versionCode = 2`、`versionName = "2.0.0"`），并在 `run.sh` 生成的 `Info.plist` 补 `CFBundleShortVersionString` 与 `CFBundleVersion`。验证：`grep -rn "1\.0" README.md MacOS/Sources Android/app/build.gradle.kts` 无残留，`./run.sh` 生成的 plist 显示 2.0.0。
- [x] 5.2 README 补「构建前置」（Rust、两个 darwin target、两个 android target、NDK r28+、`cargo-ndk`）与「从 1.0 升级」（`.txt` 备份不再被接受，导入会明确报错）。验证：在删掉全部产物的状态下按 README 命令从零构建成功。

## 6. 端到端一致性

- [x] 6.1 同一密钥同一时刻双端算出同一验证码，覆盖 SHA-1/SHA-256/SHA-512 与 6/8 位。验证：两端各取一次输出逐字比对并留档在 PR 描述里。
- [x] 6.2 备份跨端往返：macOS 导出 JSON → Android 导入 → Android 导出 → macOS 导入。验证：账户数、标题、验证码全部一致，无 skip。
- [x] 6.3 规格校验：`openspec validate refactor-shared-rust-core --strict`。验证：命令通过，无警告。

## Workflow follow-up

- 评审通过后归档本变更（`openspec archive refactor-shared-rust-core`），并在归档后确认 `openspec/specs/totp-core/spec.md`、`macos/backup-export`、`android/settings`、`macos/app-settings` 已合并到位。
- 发布前确认 2.0 的 JSON 导出→导入往返已在真机与真机上验证过（回滚无格式转换工具）。
