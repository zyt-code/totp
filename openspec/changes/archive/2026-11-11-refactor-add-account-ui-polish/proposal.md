# Proposal

## Why

录入窗口现在是一列固定标签的表单，窗口高度也是写死的。它能保存账户，但字段排列不像现在的 macOS 设置卡片，Secret 也不能直接粘贴。

## What Changes

- 窗口宽 380pt，高度随内容变化，背景使用系统材质。
- 顶部显示「新增验证码」和副标题「手动输入或扫描二维码以绑定动态口令」。
- 常用字段放进一张圆角卡片：一个名称字段和一个 Secret 字段。名称按第一个空格拆成现有的网站名和可选账户名。
- Secret 右侧有粘贴按钮。扫码图标只占位并禁用，不请求屏幕录制权限，也不调用 Vision。
- 算法、位数和周期放进默认折叠的「高级选项 (算法、位数与周期)」。默认仍是 SHA-1、6 位、30 秒。
- 底部右对齐放取消和添加。添加在名称为空或 Secret 无效时禁用。Secret 非法时在卡片下显示一行红色说明，不关闭窗口。
- 不改 Base32 规则、保存协议、Keychain 或验证码计算。不实现 CSV 导入。

## Capabilities

### New Capabilities

- `add-account-presentation`: 规定录入窗口的尺寸、卡片、折叠选项和底部按钮外观。

### Modified Capabilities

- `manual-account-entry`: 名称改为一个字段；添加按钮在无效输入时不可用；Secret 错误显示为非打断提示。

## Impact

- `Sources/TOTPApp/AddAccountForm.swift` 和窗口尺寸。
- 保存前把一个名称字段拆回现有 `siteName` 与 `username`。
- `TOTPCore` 不变。
