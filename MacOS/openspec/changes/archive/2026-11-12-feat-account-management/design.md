# Design

## Context

`AccountList` 目前只有单击复制，行文本直接取 `TOTPAccount.name`（由 `siteName + " " + username` 拼成）。`AccountMetadataRepository` 和 `SecretStore` 都已提供 `delete(id:)`。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 右键菜单驱动复制、重命名、删除，变更后刷新列表。
- 行高等、编码清理、临界颜色、分段验证码。
- 展示拆分只做一次，不靠猜空格。

**Non-Goals:**

- 编辑算法/位数/周期（仍需删除后重建）。
- 拖拽排序、批量操作、搜索。
- 改 TOTP 计算与录入流程。

## Decisions

### 1. 账户携带站点名与用户名

`TOTPAccount` 增加 `siteName` 和 `username`，`name` 改为计算属性（有用户名时 `"站点 用户名"`）。`loadAccounts` 直接传元数据字段。

备选是继续用空格拆 `name`，但 issuer 本身可能含空格（如 `Spot Auth Lab`），会把标题拆碎。字段显式传递后，标题/副标题不再有歧义，旧测试只需改构造参数。

### 2. 展示拆分是纯函数

`displayParts(siteName:username:)`：先做 `+` → 空格与百分号解码并 trim；副标题取用户名；副标题为空且标题含冒号时，按首个冒号拆成标题与副标题。

放在 `TOTPCore`，可直接单测，视图只负责排版。

### 3. 删除顺序：先密钥后元数据

`deleteAccount(id:metadata:secrets:)` 先 `secrets.delete`，再 `metadata.delete`。密钥库删除对缺失项幂等；若元数据删除抛错，`loadAccounts` 会因缺密钥跳过该记录，账户从列表消失且不残留密钥。反过来做会留下无人引用的钥匙串条目。

### 4. 重命名复用元数据保存

`renameAccount(id:name:metadata:)` 读出记录，按首个空格拆成 `siteName` / `username`，写回同一条记录。空白名称抛 `AppError.blankSiteName`，与录入校验一致。

### 5. 右键菜单与确认

`.contextMenu` 挂在整行上。重命名用 SwiftUI `.alert` 内嵌 `TextField` 预填当前名称，删除用 `.alert` 的 destructive 按钮，文案包含账户名。两者都在 `AccountList` 内以 `@State` 驱动，完成后调用外部回调，由 `TOTPApp` 重新加载列表。

### 6. 排版与颜色

标题 `.lineLimit(1)` + `.truncationMode(.tail)`，副标题 `.lineLimit(1)` + `.truncationMode(.middle)`，行高固定，不再因长邮箱变高。

剩余秒数 `<= 5` 时环形描边与验证码改用 `.orange`，否则沿用强调色与主色。

`formattedCode(_:)` 把 6 位码显示为 `"前三位 后三位"`；复制路径始终写入原始码。

## Risks / Trade-offs

- [菜单栏弹窗里的 SwiftUI alert 可能不显示在最前] → 沿用已存在的窗口激活方式；若 alert 不可见，改为独立 NSWindow 提示框。
- [`+` 解码会让真实包含加号的站点名显示为空格] → otpauth 与常见导出器都用 `+` 表示空格，优先按编码处理。
- [重命名只改展示名，不改密钥] → 符合规格；算法等高级项仍不可编辑。

## Migration Plan

旧元数据已有 `siteName` 与 `username` 字段，无需迁移。回滚是恢复按空格拆分 `name` 的渲染。

## Open Questions

无。
