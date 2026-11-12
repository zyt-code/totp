# Tasks

## 1. Form

- [x] 1.1 把录入窗口改为 380pt 宽、随内容变高的材质视图。卡片包含名称和 Secret；Secret 有粘贴和禁用的扫码按钮。高级选项默认折叠。添加按钮在名称空白或 Secret 无效时禁用，非法 Secret 在卡片下显示红色说明。确认 `swift build --product TOTPApp` 成功，且源码不引用 ScreenCaptureKit、Vision 或 CSV。

## 2. Verification

- [x] 2.1 运行 `swift test`，确认 Base32、保存和原有 RFC 测试仍通过。
