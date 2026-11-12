# Tasks

## 1. Core

- [x] 1.1 给 `TOTPAccount` 增加 `siteName` / `username`，`name` 改为计算属性，并更新 `loadAccounts` 与既有测试构造。确认 `swift build` 成功。
- [x] 1.2 添加 `displayParts`、`formattedCode`、`renameAccount`、`deleteAccount`。用 Swift Testing 覆盖加号与百分号解码、冒号拆分、6 位分段、重命名持久化、删除后两个仓库都不再含该账户。
- [x] 1.3 扩展 `AccountList` 行：标题/副标题单行截断、剩余不超过 5 秒转警示色、6 位验证码分段显示、右键菜单（复制验证码、复制账号名、重命名、删除）。确认复制进剪贴板的是未分段验证码。

## 2. Wiring and verification

- [x] 2.1 在 `TOTPApp` 接入重命名与删除回调，完成后重新加载列表。确认 `swift build --product TOTPApp` 成功。
- [x] 2.2 运行 `swift test`，确认新增测试与既有 RFC、存储测试全部通过。
- [x] 2.3 运行 `./run.sh`，确认应用正常启动、列表等高、右键菜单可用。
