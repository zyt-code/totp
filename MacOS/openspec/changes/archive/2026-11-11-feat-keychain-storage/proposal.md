# Proposal

## Why

账户和 secret 现在写死在 `MockAccounts` 里，进程退出就消失。列表要改成从本机读取，同时 secret 不能进元数据文件。

## What Changes

- 新增 Keychain 密钥库：按账户 id 增、查、改、删 secret。secret 只以原始字节进出，不写入日志或元数据。
- 新增 `AccountMetadataRepository`：保存站点名、用户名、算法、位数和周期。元数据不含 secret。
- 启动时用元数据加 Keychain 组装账户，替换 `MockAccounts.all`。仓库为空时列表为空。
- Keychain 和元数据仓库都通过协议隔离，单元测试使用内存假实现，不访问真实钥匙串。
- 不新增录入界面、CSV 导入或屏幕扫描，因此本变更不定义屏幕录制权限或 CSV 列映射。
- 算法仍使用现有 TOTP：SHA-1、SHA-256、SHA-512，6 或 8 位，周期由元数据决定。

## Capabilities

### New Capabilities

- `account-storage`: 用 Keychain 保存 secret，用本地元数据保存账户字段，并能组装成列表账户。

### Modified Capabilities

- `totp-list`: 列表数据源从进程内 Mock 改为已保存账户；空仓库显示空状态。悬停、复制和倒计时不变。

## Impact

- 新增 Keychain 封装、元数据仓库和内存假实现。
- `TOTPApp` 的列表入参从 `MockAccounts.all` 改为仓库加载结果。
- `MockAccounts` 不再作为应用数据源。
- 不改 HOTP/TOTP 计算。
