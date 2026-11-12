# Design

## Context

列表目前直接传入 `MockAccounts.all`。`TOTPAccount` 已包含名称、secret、算法、位数和周期。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- secret 与元数据分开存储。
- 仓库通过协议加载账户，测试不碰真实 Keychain。
- 应用启动时用仓库结果替换 Mock 列表。

**Non-Goals:**

- 录入界面、CSV、屏幕扫描、iCloud 同步、迁移旧 Mock 数据。

## Decisions

### 1. 两个协议，一个组装入口

`SecretStore`：`save`、`load`、`delete`。`load` 对缺失 id 返回 `nil`。`delete` 对缺失 id 不报错。

`AccountMetadataRepository`：`save`、`list`、`delete`。记录是 `AccountMetadata`，字段只有 id、siteName、username、algorithm、digits、period。`save` 按 id 替换。

`loadAccounts(metadata:secrets:)` 按 `list()` 顺序组装。缺 secret 的记录跳过。显示名是 `siteName`，有用户名时为 `"\(siteName) \(username)"`。

### 2. Keychain 只存 secret

真实实现使用 Security 框架的通用密码项：service 固定为 `local.totp.secret`，account 为账户 id，值为 secret 原始字节。不设置同步属性，不把 secret 放进可打印字段。

测试使用 `MemorySecretStore`，用字典保存字节。单元测试不调用真实 Keychain。

### 3. 元数据用本地 JSON

元数据文件放在应用支持目录的 `accounts.json`。文件内容是元数据数组，不包含 secret。测试使用 `MemoryMetadataRepository`，不写磁盘。

仓库为空时不种入 Mock 账户。`MockAccounts` 从应用启动路径删除。

### 4. 列表接入

`TOTPApp` 启动时调用 `loadAccounts`。加载失败或为空都显示现有空状态。悬停、复制和倒计时沿用 `AccountList`，不改。

### 5. 算法、屏幕录制和 CSV

元数据里的算法、位数和周期原样传给现有 `totp`，继续支持 SHA-1、SHA-256、SHA-512 与 6/8 位。本变更没有扫描或导入，所以没有权限流程，也没有 CSV 列。

## Risks / Trade-offs

- [真实 Keychain 在未签名的 SwiftPM 可执行文件上可能因访问组失败] → 单元测试只覆盖内存假实现；首次真实写入留到签名后的手动检查。
- [元数据 JSON 与 secret 可能出现一边缺失] → 组装时跳过缺 secret 的记录，不自动删元数据。
- [JSON 明文保存站点名和用户名] → 这是规格允许的元数据；secret 不在文件里。

## Migration Plan

无旧数据。回滚是恢复 `MockAccounts.all` 并停止调用仓库。

## Open Questions

无。
