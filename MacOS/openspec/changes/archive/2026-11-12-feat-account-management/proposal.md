# Proposal

## Why

列表目前只能单击复制验证码。账户录入后既不能改名，也不能删除，写错的条目会永久留在钥匙串里。同时长邮箱和带冒号的名称会把行撑高或原样显示编码字符，列表参差不齐。

## What Changes

- 每个账户行增加右键菜单：复制验证码、复制账号名、分隔线、重命名、删除账户（危险样式）。
- 重命名弹出轻量输入框，按首个空格拆成站点名和用户名，写入元数据仓库后刷新列表。
- 删除先确认「确定要删除 [账户名] 吗？此操作不可撤销」，确认后同时删除密钥库和元数据，再刷新。
- 标题与副标题强制单行，溢出按中间或尾部截断，所有行等高。
- 展示名称统一做 URL 解码（`+` 还原为空格），并按首个冒号拆分 `Issuer:Account`。
- 剩余时间不超过 5 秒时，环形进度与验证码转为警示色。
- 6 位验证码在界面上分段显示（如 `404 162`），复制进剪贴板仍是 `404162`。
- 不改 TOTP 计算、Keychain 或录入流程。

## Capabilities

### New Capabilities

- `account-management`: 从列表右键复制、重命名、删除账户，并把变更持久化到元数据仓库与密钥库。

### Modified Capabilities

- `totp-list`: 展示名称需做 URL 解码与冒号拆分。
- `popover-presentation`: 账户行单行等高、临界颜色与验证码分段显示。

## Impact

- `Sources/TOTPCore/Account.swift`：账户模型增加站点名与用户名字段，并提供展示拆分与验证码分段工具。
- `Sources/TOTPCore/Storage.swift`：新增删除账户的跨仓库操作。
- `Sources/TOTPApp/AccountList.swift`：右键菜单、重命名与删除确认、单行排版、临界颜色。
- `Sources/TOTPApp/TOTPApp.swift`：把重命名与删除回调接到仓库并刷新列表。
