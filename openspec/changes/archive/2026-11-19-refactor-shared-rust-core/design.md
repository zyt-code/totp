# Design

## Context

现状见 `proposal.md` - Why。决定实现的技术约束：

- `openspec/specs/totp-core/spec.md` 已是行为权威，两份实现各自对着它写；本次不改它的语义，只补跨边界与备份格式。
- 平台相关部分不可下沉：macOS `Storage.swift`（Keychain，234 行）、Android `AccountStore.kt`（Room + Keystore + Tink，160 行）、双端 UI 与扫码。core 只接纯计算与协议。
- 双端账户模型都没有 HOTP 账户（只有 HOTP 原语），本次不引入 `otp_type`/`counter`，避免 Room schema 与 Keychain 元数据迁移。
- 仓库无 CI；构建入口是 `MacOS/run.sh` 与 `Android/gradlew`。
- 本机实测（macOS arm64）：Rust HOTP-SHA1 0.27 µs；CryptoKit 1.9 µs；JVM `Mac.getInstance` 0.46 µs；手写 JNI 空调用 3–7 ns；`.dylib` 调用与直接内联无差异。工具链现状：`rustc 1.96` 已装，只有 `aarch64-apple-darwin` 一个 target，无 NDK、无 `cargo-ndk`。

## Goals / Non-Goals

**Goals：**

- 算法、Base32、otpauth 解析/生成、展示拆分、备份序列化只有一份实现，两端调同一份代码。
- 同一密钥同一时刻两端算出同一验证码；备份文件跨端可读。
- 构建可复现：脚本幂等，产物不入库，尺寸有上限。

**Non-Goals：**

- 不把 Keychain / Keystore / Room / 扫码 / UI 下沉到 Rust。
- 不做动态加载：macOS 静态链接，Android 走 `jniLibs`。
- 不新增 HOTP 账户类型、不同步网络、不做加密备份信封（密钥已在平台侧的 Keychain/Keystore 加密；加密信封是新加密设计与口令 UX，不在本次）。
- 不支持 `armeabi-v7a`（与现状一致：`abiFilters` 只有 `arm64-v8a`）。

## Decisions

1. **UniFFI proc-macro 生成绑定，不手写 C ABI + JNI。** 导出面有 7 个函数、3 个 record、1 个 error enum，手写要 400 行左右的胶水并自己管字符串所有权和错误映射（上一轮分析给的估算是 6 函数约 340 行，本次加批量与 JSON 后更贵）。UniFFI 直接给出 Swift `throws` 与 Kotlin 异常映射，代价值得。
   *备选（已否决）*：手写 C ABI（最小依赖，但要维护三份胶水）；UniFFI 的 `.udl` 模式（多一份接口描述文件，proc-macro 已够用）。

2. **macOS 用静态库进 `.xcframework`，不用 `.dylib`。** 静态链接省掉 `@loader_path`/rpath 与额外二进制签名；`run.sh` 现在对 `LocalDev` 证书失败会降级 ad-hoc，多一个待签名文件就是多一个失败点。
   *备选（已否决）*：`.dylib` + `codesign --deep`。实测动态调用本身不慢，但打包与签名风险凭空增加。

3. **`Package.swift` 的结构：xcframework 只装 C 接口，生成的 Swift 绑定作为普通 source target 编译。** SwiftPM `binaryTarget` 只能承载二进制 + C 头 + modulemap，把 `.swift` 塞进去不成立。
   目录：`MacOS/Frameworks/TOTPCoreFFI.xcframework`（脚本生成，不入库）+ `MacOS/Sources/TOTPCoreBindings/`（`totp_core.swift` 绑定，target 名不能与 C 模块 `totp_coreFFI` 只差大小写）。
   xcframework 的 `Info.plist` 必须写 `HeadersPath`（实施时踩到：缺它 SwiftPM 只把 `.a` 当待链接库、不建 clang 模块，`import totp_coreFFI` 直接失败，只能退化成额外加一个 C shim target 转接 modulemap）。

4. **Android：`:core` 从 `org.jetbrains.kotlin.jvm` 改为 `com.android.library`。** `jniLibs` 和 `jna.aar` 都需要 Android 环境。代价是 `:core:test` 不再能跑算法向量——JVM 加载不了 `arm64-v8a` 的 `.so`。
   *备选（已否决）*：保留纯 JVM 模块只放绑定壳（绑定本身就要 JNA + Android 运行时，壳里没东西可测）；在 JVM 单测里加载 host dylib 跑 JNA（多一套 host 构建矩阵，不值得）。

5. **向量测试归 `cargo test`；JNI 绑定由一条真机仪器测试兜底。** 现在 `./gradlew :core:test` 的 29 个用例逐条迁进 Rust 测试；Android 侧只留一条冒烟：加载 `.so`、算一个已知向量的码、JSON 往返。
   风险承认：绑定错位（符号/类型名对不上）只会在真机上暴露，所以冒烟测试是必须项而不是可选项。

6. **边界形状：`AccountParams { id, issuer, account_name, secret: Vec<u8>, algorithm, digits, period }`，密钥只以字节传。** 手写 `Debug` 输出 `<redacted>` 且不实现 `Display`。原因：`totp-core` 有「密钥不得进入文本」的要求，而 UniFFI 生成的 Kotlin record 是 `data class`，默认 `toString()` 会打印全部字段。
   连带的坑：`ByteArray` 在 Kotlin `data class` 里是引用比较，绑定层不能依赖 `AccountParams` 的值相等（比较请按 `id`）。
   数值类型：`digits`/`period`/`remaining_seconds`/`skipped` 用 `i32`、`unix_time` 用 `i64`。UniFFI 把 `u32`/`u64` 映射成 Kotlin 的 `UInt`/`ULong`，会让两端调用点到处显式转换；有符号整数在 Kotlin 是 `Int`/`Long`、Swift 是 `Int32`/`Int64`，且 `i32` 还能把「period 必须为正」的负值用例保留在测试里。

7. **不导出「规范化后返回 Base32 字符串」的便捷函数，但导出 Base32 ↔ 字节的编解码。** 前者的返回值就是密钥文本、与决定 6 冲突，且解析路径里没有调用方。后者有真实调用方：macOS 手工录入表单需要「文本 → 字节」保存、以及把已存密钥回填到输入框（`decode_base32_secret` / `encode_base32_secret`）；靠 `otpauth://` 拼接来转换会把 `+` 和查询串字符卷进来，属于在输入边界上自找麻烦。

8. **批量接口 `generate_codes_batch(accounts, now)`：** UI 每秒 tick 只跨边界一次。UniFFI 的 Kotlin 侧走 JNA，单次调用比手写 JNI 贵（JNA 分发 + 封送），批量是保守选择；即使不优化也能用。
   *备选（已否决）*：逐账户调用（每秒 N 次边界）；把整列表以 JSON 串过边界（序列化成本远大于计算）。

9. **备份 JSON：`{"format":"totp-backup","version":2,"accounts":[...]}`。** `format` + `version` 两个字段是为了以后能拒绝未知格式并给出可读错误，而不是靠"解析失败"猜。导入只认这一种；1.0 的行文本按规格被拒绝且明确报格式错误（用户已确认完全切换）。
   *备选（已否决）*：导入兼容旧行文本（用户明确要求完全切换）。

10. **展示名称规则取 Android 版本（冒号优先 → 空格回退 → 重复 token 折叠）。** 它是 macOS 规则（仅冒号）的超集，能处理历史数据里 `Issuer:Account` 与 `Issuer Account me@x.com me@x.com` 两种残形。macOS 侧标题会有可见变化，已写进规格 delta。

11. **`otpauth` 解析用 `url` + `percent-encoding`，但对 query 值保留 `+`→空格 的兼容处理。** 两端现状都这么做；`url` crate 不会把 `+` 当空格，直接换会改变行为。需要一条测试向量钉住。
    *备选（已否决）*：`data-encoding` 做 Base32（它不做空格/连字符预处理，规格要的是"忽略空格与连字符、拒绝非法 pad"，手写 20 行更直接，且两份现有实现的语义已在规格里）。

12. **release profile：`opt-level = "z"`、`lto = true`、`codegen-units = 1`、`strip = true`、`panic = "abort"`。** `"z"` 会让 HMAC 比实测的 `opt-level = 3` 慢一些（预计 2–3 倍，仍是亚微秒级，对 30 秒周期无意义），换体积。`panic = abort` 意味着 core 里的 panic 会终止进程而不是抛异常——接受：这段代码 panic 即 bug，24 行算法不该有可恢复的 panic。

13. **产物不入库。** `.gitignore` 加 xcframework、`jniLibs`、生成绑定目录；由 `run.sh` / gradle / 脚本生成。
    *备选（已否决）*：提交产物让无 Rust 环境的开发者能直接编译（仓库会膨胀，且二进制与源码静默不同步，无 CI 时更危险）。

14. **版本 2.0.0。** 备份格式是破坏性变更，按主版本 +1；三处版本源（README、`Preferences.version`、gradle）与 `run.sh` 的 `Info.plist` 一起改，README 增加「从 1.0 升级」。

## Risks / Trade-offs

- [`core` panic 直达进程退出] → 只在纯函数里使用 `unwrap` 外的显式错误返回；`cargo test` 覆盖拒绝路径；`panic = "abort"` 写进 crate 注释。
- [16 KB 页对齐] `targetSdk 37` 下 `.so` 必须 16 KB 对齐 → 固定 NDK r28+，构建脚本用 `llvm-readelf -l` 断言 LOAD 对齐 ≥ 2**14，不通过就失败。
- [绑定错位只在真机暴露] → 一条仪器冒烟测试（见决定 5），并在 `:app` 构建后立即跑。
- [工具链缺失] 开发机无 NDK/target/`cargo-ndk` → 两个脚本先探测依赖并打印缺什么再退出，README 写明前置；首次约 1–2 GB 下载。
- [`:core` 的 JVM 单测消失] 覆盖率从 29 个 JVM 用例转到 `cargo test`，数量必然不同 → 按用例清单迁移（RFC 向量、6/8 位、三算法、拒绝路径、URI 缺省与拒绝、名称拆分、备份往返/拒绝），迁完逐条对照旧测试文件。
- [1.0 备份失效] 用户手里的 `.txt` 无法导入 → 导入报错文案明确写「2.0 只接受 JSON 备份」；README 升级段落说明升级前先在 1.0 客户端导入或重新录入。发布前必须验证 JSON 导出→导入往返，否则回滚无工具。
- [JNA 体积与分发开销] `jna.aar` 约 200 KB/ABI，单次调用比手写 JNI 贵 → 用批量接口压住调用次数；接受体积。
- [无 CI] 4 个构建产物靠脚本 → 脚本幂等、失败即非零退出；尺寸与对齐检查放进脚本而不是文档。

## Migration Plan

1. 落 `core/` + 两个构建脚本，`cargo test` 全绿；此时两端仍在用旧实现，未发布。
2. macOS 切绑定，删旧实现与旧测试，`swift test` + `./run.sh` 通过。
3. Android 切绑定，删旧实现与旧测试，`assembleDebug` + 真机冒烟通过。
4. 备份格式切 JSON，版本升 2.0.0，README 补前置条件与升级说明。
5. 端到端一致性验证（同码、跨端往返）后发布。

**Rollback：** 发布前整体 revert 本变更即可（旧实现完整保留到最后一步才删）；发布后回滚需要把 2.0 的 JSON 备份转回 1.0 的行文本，仓库里没有这个工具，因此步骤 4 之前必须验证过 JSON 往返。

## Open Questions

- `uniffi` 的具体版本与它要求的 `jna` 版本：实施第一步用 `cargo add uniffi` 解析当时可用版本并锁定 `Cargo.lock`，不影响规格、方案与任务拆分。
