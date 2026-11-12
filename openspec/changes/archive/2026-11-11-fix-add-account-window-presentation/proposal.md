# Proposal

## Why

空状态的「添加第一个账户」和底部加号目前没有弹出录入窗口。菜单栏应用没有普通窗口场景，SwiftUI 的 `Window` 和 `.sheet` 都不能从 `MenuBarExtra` 可靠地挂出来。

## What Changes

- 用一个独立的 AppKit 窗口控制器显示现有录入表单，不再使用 SwiftUI `Window` 或 `.sheet`。
- 窗口标题为「新增 TOTP 账户」，样式包含标题栏、关闭和最小化，层级为浮动，并在屏幕中央显示。
- 打开前激活应用。窗口已存在时只把它带到前面，不创建第二个。
- 空状态按钮和底部加号都调用同一个打开方法。
- 保存成功或取消后关闭窗口。保存成功后刷新账户列表；取消不保存。
- 不改 TOTP 计算、Base32 校验、Keychain 或元数据格式。不新增屏幕扫描或 CSV 导入。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `manual-account-entry`: 录入窗口必须作为可激活、可复用的独立窗口打开，并支持取消关闭。

## Impact

- `Sources/TOTPApp/TOTPApp.swift` 的打开和关闭路径。
- 新增一个 AppKit 窗口控制器，继续承载现有 `AddAccountForm`。
- `TOTPCore` 不变。
