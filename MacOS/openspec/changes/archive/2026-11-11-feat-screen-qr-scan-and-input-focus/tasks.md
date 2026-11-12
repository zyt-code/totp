# Tasks

## 1. URI

- [x] 1.1 添加 `parseOtpauth`。用 Swift Testing 断言完整 URI 得到名称、Secret、SHA-256、8 位和周期 45；缺省字段得到 SHA-1、6 位和 30 秒；缺 Secret 或未知算法失败。

## 2. Focus and scan

- [x] 2.1 让录入窗口可以成为键盘窗口，打开时激活、置前并聚焦名称字段。Return 提交有效表单，Escape 取消。确认 `swift build --product TOTPApp` 成功。
- [x] 2.2 启用扫码按钮。未授权时只显示设置引导且不截屏；已授权时截取主屏幕一次并用 Vision 识别。恰好一个有效 otpauth 二维码才填表，否则保留原值并显示原因。Info.plist 增加屏幕录制用途说明。确认源码不解析 CSV。

## 3. Verification

- [x] 3.1 运行 `swift test`，确认 URI、Base32、保存和原有 RFC 测试都通过。
