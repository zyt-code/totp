# Proposal

## Why

状态栏图标原本是 `lock`，和主图标里的「锁 + 计时」语言不一致；新增账户窗口为了拿到键盘焦点会把应用切成 `.regular`，但关闭后没有切回 `.accessory`，Dock 里会留下一个退不掉的图标。

## What Changes

- 状态栏状态项改用 `lock.badge.clock` 模板符号，由系统按菜单栏明暗自动着色。
- `AddAccountWindowController` 监听窗口关闭，在没有其他可见编辑窗口时把激活策略切回 `.accessory`。取消、保存成功、Esc、红叉四条路径共用同一次关闭。
- `run.sh` 重启前等待旧进程真正退出，避免 `pkill` 与 `open` 竞态导致 `error -600`。
- 不改 TOTP 计算、存储、列表和录入表单。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `app-skeleton`: 增加状态项外观与关闭编辑窗口后恢复纯菜单栏形态两条要求。

## Impact

- `Sources/TOTPApp/TOTPApp.swift`：状态项符号。
- `Sources/TOTPApp/AddAccountWindowController.swift`：窗口关闭时恢复激活策略。
- `run.sh`：重启等待。
