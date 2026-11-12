# Proposal

## Why

新增窗口打开后，文本框不一定能接收键盘输入，所以名称和 Secret 无法录入，添加按钮保持禁用。Secret 旁的扫码按钮也仍是禁用占位，不能从屏幕上的 `otpauth://` 二维码填表。

## What Changes

- 录入窗口声明可以成为键盘窗口。打开时激活应用、置前，并把焦点交给名称字段。Return 提交有效表单，Escape 取消。
- 启用扫码按钮。点击后先检查屏幕录制权限；未授权时显示说明，并提供打开系统设置的入口，不截屏。
- 已授权时截取主屏幕一次，用 Vision 识别二维码。识别到一个 `otpauth://totp` URI 后填入名称、Secret、算法、位数和周期。
- 新增 `otpauth` 解析：支持 `secret`、`issuer`、`algorithm`、`digits`、`period`，以及标签里的账户名。未知算法、位数或周期拒绝，不覆盖已有表单。
- 没有二维码、多个二维码或 URI 无效时保留原表单，并显示一行原因。
- 不改 TOTP 计算、Keychain、元数据格式或 CSV 导入。

## Capabilities

### New Capabilities

- `otpauth-uri`: 解析标准 `otpauth://totp` URI，并在字段缺失时使用现有默认值。
- `screen-qr-scan`: 检查屏幕录制权限，截取主屏幕一次并识别二维码；拒绝授权时不截屏。

### Modified Capabilities

- `manual-account-entry`: 窗口必须接收键盘输入；扫码结果可以填入现有表单。
- `add-account-presentation`: 扫码按钮从禁用占位改为可执行的屏幕识别入口。

## Impact

- `AddAccountWindowController` 的键盘焦点。
- `AddAccountForm` 的扫码按钮和字段赋值。
- `TOTPCore` 新增 URI 解析，不改 HMAC 或存储。
- 应用需要屏幕录制权限声明。
