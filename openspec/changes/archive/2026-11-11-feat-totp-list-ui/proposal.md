# Proposal

## Why

菜单栏现在只有一个禁用的「TOTP 列表」占位。验证码计算已经可用，但用户还不能看到账户、剩余时间和当前验证码，也不能复制。

## What Changes

- 用内存中的固定 Mock 账户替换禁用的列表占位。菜单仍保留分隔线、禁用的新增、禁用的设置和可用的退出。
- 每一行显示账户名。指针悬停时显示当前 TOTP、环形剩余时间进度和剩余秒数；离开后隐藏验证码。
- 单击整行把当前验证码写入系统剪贴板，并在该行显示短暂的已复制反馈。约 30 秒后清除剪贴板中仍等于该验证码的内容。
- 验证码继续使用现有 TOTP 计算：SHA-1、SHA-256、SHA-512，6 或 8 位，默认 30 秒周期。Mock 至少覆盖这三种算法和两种位数。
- 不新增持久化、手动录入、CSV 导入或屏幕扫描。因此本变更不定义屏幕录制权限或 CSV 列映射。

## Capabilities

### New Capabilities

- `totp-list`: 从内存账户渲染菜单列表，悬停显示验证码和剩余时间，单击复制并给出反馈。

### Modified Capabilities

- `app-skeleton`: 菜单里的禁用 TOTP 列表占位改为真实列表；新增和设置仍不创建账户。

## Impact

- `Sources/TOTPApp/TOTPApp.swift` 的 `MenuBarExtra` 内容。
- 应用目标新增剪贴板写入和定时清除；不写 Keychain，不保存 secret。
- `TOTPCore` 的 HOTP/TOTP 计算不改。
