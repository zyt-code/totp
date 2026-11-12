# Design

## Context

`AddAccountForm` 现在是一列带标签的字段，窗口尺寸固定。保存接口仍接收分开的 `siteName` 和 `username`。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 用一个随内容变高的卡片窗口替换固定表单。
- 常用字段只留名称和 Secret。
- 高级选项默认折叠，扫码按钮不产生扫描行为。

**Non-Goals:**

- 实现屏幕扫描、Vision、CSV、编辑已有账户。
- 改 Base32、`saveAccount` 或存储格式。

## Decisions

### 1. 窗口尺寸跟着内容走

窗口宽 380。内容使用 `.regularMaterial`，高度由 SwiftUI 视图决定，窗口在显示时按内容尺寸调整并重新居中。系统标题栏保留「新增 TOTP 账户」；视图内部另有大标题「新增验证码」。

### 2. 一个名称字段

表单不再显示单独的账户名输入。保存时按第一个空格拆分：前面是 `siteName`，后面是 `username`。没有空格时用户名为空。这样现有保存接口和列表的 `"站点 用户名"` 格式不用改。

### 3. Secret 辅助按钮

粘贴读取剪贴板字符串并替换 Secret。扫码按钮显示 `qrcode.viewfinder`，`.disabled(true)`，没有动作。它不引用 ScreenCaptureKit 或 Vision。

### 4. 折叠和按钮状态

`DisclosureGroup` 初始为关闭。添加按钮在名称空白或 `decodeBase32` 失败时禁用。Secret 非空且解码失败时，在卡片下显示一行 `.caption` 红色文本。空 Secret 只禁用按钮，不显示错误，避免刚打开就报错。

取消继续只关闭窗口。添加沿用现有保存和刷新。

### 5. 屏幕录制和 CSV

扫码按钮是占位，不查屏幕录制权限，失败路径也不存在。CSV 不在本变更。以后实现扫码时再单独处理权限；拒绝后不抓屏。

## Risks / Trade-offs

- [名称里的第一个空格会被当成用户名分隔] → 与现有列表的 `"站点 用户名"` 格式一致；不增加第二个名称字段。
- [窗口随展开高级选项变高] → 展开后重新按内容调整高度，不保留固定空白。

## Migration Plan

无数据。回滚是恢复原来的固定高度表单。

## Open Questions

无。
