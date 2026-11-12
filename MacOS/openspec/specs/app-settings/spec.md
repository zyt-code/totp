# app-settings Specification

## Purpose

提供原生设置窗口，让用户控制登录启动、剪贴板清理与验证码显示，并查看应用信息。它只约束设置窗口与偏好，不改变验证码计算或账户存储。

## Requirements

### Requirement: Settings window

The gear button MUST open one detached settings window about 440 points wide that sizes its height to content and uses the grouped form style. Escape and the window close button MUST close it.

#### Scenario: Opens from the gear button

- **WHEN** the user activates the gear button
- **THEN** one settings window opens in the grouped form style

#### Scenario: Closes by Escape or close button

- **WHEN** the user presses Escape or clicks the close button
- **THEN** the settings window closes

### Requirement: Launch at login

The "登录时自动启动" switch MUST register or unregister the main app with `SMAppService` and MUST show the current registration status when the window opens. A failed registration MUST surface a readable message instead of silently reverting.

#### Scenario: Enabling registers the app

- **WHEN** the user turns on "登录时自动启动"
- **THEN** the app is registered as a login item and the switch stays on

#### Scenario: Status reflects reality

- **WHEN** the settings window opens
- **THEN** the switch reflects the current login-item registration status

#### Scenario: Failure is reported

- **WHEN** registration fails
- **THEN** the window shows a readable message and the switch returns to the actual state

### Requirement: Clipboard auto-clear preference

Auto-clear MUST be enabled by default with a delay of 30 seconds and MUST offer 15, 30, and 60 second choices. When enabled, copying a code MUST schedule a clear at that delay, and the app MUST clear the clipboard only if it still contains that same code. With auto-clear disabled the clipboard MUST be left untouched.

#### Scenario: Matching content is cleared

- **WHEN** the configured delay passes and the clipboard still holds the copied code
- **THEN** the clipboard is cleared

#### Scenario: Replaced content is kept

- **WHEN** the user copies something else before the delay passes
- **THEN** the app leaves that content in place

#### Scenario: Auto-clear disabled

- **WHEN** the switch is off and a code is copied
- **THEN** the clipboard is never cleared by the app

### Requirement: About and storage status

The settings window MUST show the app name, the version "v1.0.0", and the status line "本地 Keychain 加密存储 · 零网络权限".

#### Scenario: About section

- **WHEN** the settings window is shown
- **THEN** the app name, "v1.0.0", and the storage status line are visible
