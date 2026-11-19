# Proposal

## Why

2.0 的共享核心在合并前 review 中发现六处边界问题：两个构建脚本只编 `--lib` 却直接调用 `uniffi-bindgen`，清空 `target/` 后从零构建会断；`ANDROID_NDK_HOME` 指向具体 NDK 时脚本仍下钻一层，拿错路径；备份导入让单条坏账户拖垮整个文档；`otpauth` 把 `secret` 里的 `+` 当空格忽略，可能静默接受错误密钥；带 issuer 的扫码结果在账户名重复时不折叠；`format_otpauth_uri` 无调用方却仍暴露 FFI。

这些问题已在实现中修复，但其中两条改变了 `totp-core` 的 spec 行为：`secret` 中的 `+` 必须被拒绝，展示名称对存储账户名也折叠重复 token。本 change 把这两条需求变更、修复任务和验证结果补齐为可归档记录。

## What Changes

- 构建：两个脚本显式 `cargo build --release --bin uniffi-bindgen` 并校验；Android NDK 解析支持 `ANDROID_NDK_HOME` 直指 NDK 或指向版本父目录，未设置时回退 `$ANDROID_HOME/ndk` 最新版。
- 备份导入：先解析外层 `format/version/accounts`，再逐条反序列化；坏条目计入 `skipped`，不再整体报格式错误。
- `otpauth` 解析：表单编码的 `+`→空格只作用于 issuer 等展示字段；`secret` 保留字面 `+`，交由 Base32 拒绝（含 `%2B`）。
- 展示：`naming::display` 对非空存储账户名也折叠重复 token，修复 `GitHub:ada ada` 走 issuer 分支后副标题仍显示 `ada ada`。
- FFI：移除无调用方的 `format_otpauth_uri`；formatter 降级为测试工具。
- **BREAKING**：此前把 `secret` 中的 `+` 当空格接受的 otpauth URI 现在会失败；客户端对这类输入只显示通用“无效二维码/无效 TOTP 账户”。

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- `totp-core`：Base32 secret validation 增加 `+` 拒绝场景；Display name normalization 对 subtitle（含存储账户名）折叠重复 token。

## Impact

- 代码：`core/scripts/build-android.sh`、`core/scripts/build-macos.sh`、`core/src/backup.rs`、`core/src/lib.rs`、`core/src/naming.rs`、`core/src/otpauth.rs`、`openspec/specs/totp-core/spec.md`。
- 行为：`secret` 含 `+` 的 URI 由接受变拒绝；已存账户名如 `ada ada` 的副标题显示为 `ada`。
- 测试：`cargo test` 39/39；`swift test` 16/16；Android 仅 JVM 单测；`openspec validate --all` 全绿。
