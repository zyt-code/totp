# Design

## Context

`totp-core` 是双端唯一的可执行实现。本轮改动同时触及构建产物生成、外部协议解析和展示规则；其中只有 `secret` 的 `+` 规则与展示折叠属于 spec 级行为变更，其余是修复实现与既有需求的偏差。

## Decisions

1. **`+` 只在 `secret` 保留字面量。** `url::form_urlencoded` 在解码 query 时无条件把 `+` 变空格；先把 query 里的 `+` 转成 `%2B` 再解析，才能让 `secret` 拿到原样 `+` 交给 Base32 拒绝。`issuer`/`algorithm`/`digits`/`period` 继续沿用 `+`→空格，保持两端既有兼容。代价是历史上依赖 `+` 表示空格的 secret URI 会失败；这是有意的安全收紧，规格补了场景。

2. **重复 token 折叠放在 `naming::display`。** 存储层保留原始账户名，仅展示层折叠；不迁移数据，两端调用同一导出函数。`collapse` 只在所有 token 相同且至少两个时生效。

3. **备份导入分层解析。** 外层信封用 `Document<serde_json::Value>` 校验 `format`/`version`/`accounts`；单条用 `from_value::<Entry>` 失败即计入 `skipped`。这样格式错误与单条非法仍可区分，符合既有 “Backup import validation”。

4. **构建工具显式化。** `cargo build --lib` 不产出 `uniffi-bindgen`；两个脚本都显式构建 bin 并 `test -x`。Android NDK 优先 `ANDROID_NDK_HOME`，值不是 NDK 时按旧用法下钻一层；未设置时用 SDK 最新 NDK，最后统一校验 `source.properties` 与 `toolchains`。

5. **删除无调用方的 FFI formatter。** 保留 `otpauth::format` 与 round-trip 测试，用 `#[cfg(test)]` 隔离；将来二维码/导出有真实调用方时再导出。

## Risks

- `secret` 含 `+` 的历史 URI 会失败；客户端只显示通用错误。
- `ANDROID_NDK_HOME` 指向父目录时依赖“最新子目录”，若最新目录无效会报错而不是回退更旧版本。
