# Design

## Context

两个新增按钮都把 `showingAdd` 设为 true，再调用 SwiftUI `openWindow`。应用只有 `MenuBarExtra`，这个窗口不会显示。表单和保存逻辑已经可用。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 用一个可复用的 AppKit 窗口显示现有表单。
- 打开前激活菜单栏应用。
- 保存成功或取消后关闭窗口；只有保存成功才刷新列表。

**Non-Goals:**

- 改 Base32、`saveAccount`、Keychain、元数据或弹窗布局。
- 屏幕扫描、CSV、编辑已有账户。

## Decisions

### 1. 一个窗口控制器

新增 `AddAccountWindowController: NSWindowController`。窗口使用 `.titled`、`.closable`、`.miniaturizable`，标题为「新增 TOTP 账户」，`level = .floating`，首次 `center()`。内容是现有 `AddAccountForm` 的 `NSHostingView`。

控制器保存为应用上的一个属性。打开时先调用 `NSApp.activate(ignoringOtherApps: true)`。已有窗口只执行 `makeKeyAndOrderFront(nil)`。

### 2. 取消是关闭，不是保存

表单增加取消按钮，调用控制器的关闭动作。关闭不调用 `saveAccount`，也不重新加载列表。保存仍走现有 `save()`；成功后关闭这个控制器并调用现有 `reload()`。校验失败时窗口保持打开。

### 3. 两个按钮共用一个方法

空状态按钮和底部加号继续共用 `AccountList` 的 `onAdd`。`onAdd` 改为调用控制器的打开方法，不再使用 `showingAdd`、`openWindow` 或 `dismissWindow`。删除 SwiftUI `Window("新增账户")`。

### 4. 屏幕录制和 CSV

本变更没有扫描或导入，所以没有权限流程，也没有 CSV 列。以后做扫描时再单独查屏幕录制权限；拒绝后不抓屏。

## Risks / Trade-offs

- [浮动窗口可能盖住正在使用的应用] → 这是无 Dock 图标应用获得焦点所需要的；关闭后不再保留。
- [SwiftUI 状态放在 App，AppKit 窗口只是宿主] → 表单绑定保持在 `TOTPApp`，控制器不复制一份状态。

## Migration Plan

无数据。回滚是恢复 SwiftUI `Window` 场景。

## Open Questions

无。
