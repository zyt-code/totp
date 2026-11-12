# Proposal

## Why

底部齿轮按钮目前是禁用的占位。登录时启动、剪贴板清理延迟、验证码分段显示都写死在代码里，账户也无法批量迁出。用户没有任何可配置项。

## What Changes

- 启用齿轮按钮，打开独立的原生设置窗口（宽约 440pt、随内容变高、`.formStyle(.grouped)`）。
- 设置窗口打开时切 `.regular` 并置前；关闭时若无其他可见编辑窗口，恢复 `.accessory`，Dock 图标随之消失。
- 常规：登录时自动启动，接入 `SMAppService.mainApp`，同步注册状态并在失败时提示。
- 安全：复制后自动清空剪贴板（默认开）与延迟选择（15/30/60 秒，默认 30）。到点只清理仍等于刚才验证码的内容。
- 显示：验证码分段显示开关（默认开）。关闭后显示连续数字；复制始终是无空格纯数字。
- 数据：导出 otpauth URI 备份，经保存面板写为换行分隔的文本文件，操作前确认。
- 关于：显示应用名、`v1.0.0` 与「本地 Keychain 加密存储 · 零网络权限」。
- 偏好全部用 `@AppStorage` 持久化。不改 TOTP 计算、Keychain、账户存储格式。

## Capabilities

### New Capabilities

- `app-settings`: 设置窗口的生命周期、四项用户偏好与关于信息。
- `backup-export`: 把账户序列化为 otpauth URI 并导出为文本备份。

### Modified Capabilities

- `app-skeleton`: 齿轮按钮从禁用改为打开设置窗口；编辑窗口关闭后的激活策略恢复覆盖设置窗口。
- `popover-presentation`: 底部工具栏的齿轮按钮不再是无动作的禁用项。
- `totp-list`: 复制后的剪贴板清理改为按偏好开关与延迟执行。

## Impact

- 新增 `Sources/TOTPApp/SettingsWindowController.swift` 与设置视图，齿轮按钮接线。
- `Sources/TOTPApp/AccountList.swift` 读取分段显示与剪贴板偏好。
- `Sources/TOTPCore/Account.swift` 新增 Base32 编码与 otpauth 序列化。
- 剪贴板比对逻辑抽成纯函数以便单测。
