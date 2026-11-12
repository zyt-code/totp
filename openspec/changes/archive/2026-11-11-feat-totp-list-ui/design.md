# Design

## Context

`MenuBarExtra` 里现在是一个禁用的「TOTP 列表」按钮。`TOTPCore.totp` 已经能按账户的算法、位数和周期计算验证码。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 用同一套行模型驱动菜单列表，倒计时和验证码不写在视图里。
- 悬停才显示验证码；单击复制，并在剪贴板仍是该码时清除。

**Non-Goals:**

- 持久化、录入、CSV、屏幕扫描、搜索、滚动窗口优化。

## Decisions

### 1. 列表替换占位按钮

`MenuBarExtra` 内容改为：账户列表、分隔线、禁用的新增、禁用的设置、退出。空列表显示一个禁用的「没有账户」行。新增和设置保持空动作。

SwiftUI 菜单不能可靠地做指针悬停和环形进度。列表区用一个固定宽度的 SwiftUI 视图，不用一串 `Button`。

### 2. 行状态与视图分开

`TOTPAccount` 只保存名称、`Secret`、算法、位数和周期。三个 Mock 账户覆盖 SHA-1/6、SHA-256/6、SHA-512/8，周期都是 30 秒，secret 用现有 RFC 种子，仍只活在内存里。

纯函数：

- `remainingSeconds(time:period:)`：`period - time % period`；周期结束时为 `period`，下一次 tick 变为新周期。
- `ringFraction(time:period:)`：`remainingSeconds / period`。
- `currentCode(account:time:)`：调用现有 `totp`。

视图每秒刷新一次。悬停用 `onHover`。环形用 `Circle().trim`，中间放剩余秒数。验证码用等宽字体。

### 3. 剪贴板

单击整行调用 `NSPasteboard.general` 写入当前验证码，并在该行把名称替换为「已复制」，2 秒后恢复。写入时记录该字符串；30 秒后仅当剪贴板仍等于它时才清空。用户换过内容则不动。

清除只比较验证码字符串，不读取或记录其他剪贴板类型。

### 4. 算法兼容

不改 `TOTPCore`。行上的算法和位数原样传给 `totp`，所以 SHA-1、SHA-256、SHA-512 与 6/8 位沿用已测试的实现。

### 5. 屏幕录制和 CSV

本变更没有扫描或导入，所以没有权限流程，也没有 CSV 列。以后做扫描时再单独查屏幕录制权限；拒绝后不抓屏。

## Risks / Trade-offs

- [菜单里的自定义悬停视图在不同 macOS 版本上点击区域可能不同] → 整行用同一个点击动作，不用行内按钮。
- [30 秒清剪贴板可能清掉用户刚粘贴后仍留在剪贴板的同一串数字] → 这是规格要求的隐私行为；只在内容仍相等时清除。
- [Mock secret 仍以明文留在进程内存] → 不落盘；持久化变更必须改走 Keychain 或 AES-GCM。

## Migration Plan

无数据。回滚是恢复原来的占位菜单。

## Open Questions

无。
