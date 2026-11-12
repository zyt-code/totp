# Tasks

## 1. Window

- [x] 1.1 添加 `AddAccountWindowController`：标题「新增 TOTP 账户」，标题栏、关闭和最小化，浮动并居中。打开前激活应用；已有窗口只带到前面。确认 `swift build --product TOTPApp` 成功。
- [x] 1.2 让空状态按钮和底部加号调用同一个打开方法。表单增加取消；取消关闭且不保存，保存成功后关闭并刷新列表。删除 SwiftUI `Window` 场景。确认源码不引用 ScreenCaptureKit、Vision 或 CSV。

## 2. Verification

- [x] 2.1 运行 `swift test`，确认 Base32、保存和原有 RFC 测试仍通过。
