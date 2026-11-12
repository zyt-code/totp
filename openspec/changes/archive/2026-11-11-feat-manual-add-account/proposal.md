# Proposal

## Why

新增按钮目前是禁用的。仓库已经能保存账户，但用户还没有办法录入一个账户。

## What Changes

- 启用「新增」。点击后打开一个独立的 SwiftUI 录入窗口。
- 表单包含网站/机构名称、可选账户名、Secret、算法、位数和周期。默认值为 SHA-1、6 位、30 秒。算法可选 SHA-256、SHA-512，位数可选 8。
- Secret 先去掉空格和连字符，再按 Base32 校验。非法字符、空值和错误填充都拒绝保存。
- 保存时把元数据写入 `AccountMetadataRepository`，把解码后的 secret 写入 `SecretStore`，然后关闭窗口并刷新菜单列表。
- 网站名为空或 Secret 无效时不保存，并在表单上显示原因。
- 不新增屏幕扫描、Vision 或 CSV 导入，因此本变更不定义屏幕录制权限或 CSV 列映射。设置仍保持禁用。

## Capabilities

### New Capabilities

- `manual-account-entry`: 校验 Base32 Secret，保存账户元数据和密钥，并让列表显示新账户。

### Modified Capabilities

- `app-skeleton`: 「新增」从禁用占位改为打开录入窗口；设置仍不创建账户。

## Impact

- `TOTPApp` 的新增按钮和账户列表状态。
- 新增 Base32 解码与录入表单。
- 继续使用现有元数据仓库和 Keychain secret store。
- 不改 HOTP/TOTP 计算。
