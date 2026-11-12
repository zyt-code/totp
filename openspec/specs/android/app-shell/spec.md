# app-shell Specification

## Purpose

提供可启动的 Android 应用壳：Material 3 界面、动态取色、edge-to-edge，以及离线与防截屏约束。它不包含账户存储或验证码计算。

## Requirements

### Requirement: Offline manifest

The packaged app MUST NOT declare the `INTERNET` permission. The only dangerous permission it declares MUST be `CAMERA`.

#### Scenario: No network permission

- **WHEN** the packaged manifest is inspected
- **THEN** it does not contain the `INTERNET` permission and does contain `CAMERA`

### Requirement: Secure window

Windows that show a verification code MUST set `FLAG_SECURE` unless the user turned on the screenshot preference. Changing that preference MUST add or clear the flag immediately, without restarting the app.

#### Scenario: Protected by default

- **WHEN** the app shows the account list and the screenshot preference is off
- **THEN** the window has `FLAG_SECURE` set

#### Scenario: User allows screenshots

- **WHEN** the user turns on the screenshot preference while the list is open
- **THEN** the window clears `FLAG_SECURE` and recents thumbnails are no longer blocked

### Requirement: Material 3 edge-to-edge shell

The app MUST use Material 3, enable dynamic color when the device provides it, and draw edge-to-edge with content inset from system bars.

#### Scenario: Launch

- **WHEN** the app launches on a device that supports dynamic color
- **THEN** the UI uses Material 3 dynamic color and content is not hidden under the system bars
