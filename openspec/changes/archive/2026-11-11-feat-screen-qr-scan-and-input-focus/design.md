# Design

## Context

录入窗口已经是独立的 `NSWindowController`，打开时会激活应用并调用 `makeKeyAndOrderFront`。扫码按钮仍是禁用占位。行为见本变更的规格。

## Goals / Non-Goals

**Goals:**

- 让名称和 Secret 能接收键盘输入，Return 和 Escape 有明确动作。
- 把一个 `otpauth://totp` URI 解析成现有表单字段。
- 已授权时只截取主屏幕一次；未授权时不截屏。

**Non-Goals:**

- 持续屏幕录制、选择窗口、识别图片文件、CSV 导入。
- 改 HMAC、Keychain 或元数据格式。

## Decisions

### 1. 键盘焦点

使用一个 `NSWindow` 子类，`canBecomeKey` 返回 true。`show()` 继续先调用 `NSApp.activate(ignoringOtherApps: true)`，再 `makeKeyAndOrderFront`。名称字段使用 `@FocusState`，窗口出现后请求焦点。

表单的添加按钮保留 `.defaultAction`，取消按钮保留 `.cancelAction`。这样 Return 只提交可保存的表单，Escape 关闭且不保存。

### 2. URI 解析放在 TOTPCore

`parseOtpauth(_:)` 使用 `URLComponents`。只接受 scheme `otpauth` 和 host `totp`。`secret` 必填。标签按 `issuer:account` 拆分；query 里的 `issuer` 优先。显示名沿用 `"issuer account"`，只有一个时不补空格。

`algorithm` 只接受 SHA1、SHA256、SHA512。`digits` 只接受 6 或 8。`period` 必须是正整数。缺省值分别是 SHA-1、6、30。解析失败抛现有的 `AppError.invalidSecret`，不新增错误类型。

### 3. 扫码是一次截图

扫码先调用 `CGPreflightScreenCaptureAccess()`。返回 false 时用 `NSAlert` 说明需要屏幕录制权限；确认后打开 `x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`。取消或未授权都不调用截屏。

已授权时用 `CGDisplayCreateImage` 截取主显示器一次，再交给 `VNDetectBarcodesRequest`，只接受 `.qr`。结果不是恰好一个可解析的 otpauth payload 时，表单不变，并在现有错误位置显示原因。

应用 Info.plist 增加 `NSScreenCaptureUsageDescription`。

### 4. 表单赋值

解析结果直接写入现有绑定：名称、Secret、算法、位数、周期。Secret 仍走现有 Base32 校验后才能启用添加按钮。扫码不自动保存。

### 5. CSV

本变更没有导入，所以没有 CSV 列映射。扫码权限失败只停在提示，不截屏。

## Risks / Trade-offs

- [菜单栏应用的屏幕录制权限可能要重启应用后才生效] → 提示里说明需要重新打开应用；本次不自动重启。
- [主屏幕截图可能包含无关二维码] → 多于一个结果就失败，不猜测哪一个。
- [Return 在名称字段里仍会触发默认按钮] → 这是规格要求的提交行为；多行输入不在本变更。

## Migration Plan

无数据。回滚是恢复禁用的扫码按钮和原来的窗口类。

## Open Questions

无。
