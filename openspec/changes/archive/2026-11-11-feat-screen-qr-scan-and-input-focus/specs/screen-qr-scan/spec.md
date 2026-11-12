# Spec Delta

## Purpose

从主屏幕的一次截图中识别 otpauth 二维码，并在没有屏幕录制权限时停止且不截屏。

## ADDED Requirements

### Requirement: Screen recording permission

Before capturing, the app MUST check the screen recording permission. When permission is absent, it MUST show an alert explaining the need and offering to open System Settings at Privacy & Security, Screen Recording. It MUST NOT capture the screen in that state. After the user denies or cancels, the form remains usable.

#### Scenario: Permission missing

- **WHEN** the user starts a scan without screen recording permission
- **THEN** an alert offers to open the Screen Recording settings and no screen image is captured

#### Scenario: Permission denied

- **WHEN** the user cancels the permission alert
- **THEN** the add form stays open and unchanged

### Requirement: One-shot QR detection

When permission is granted, the app MUST capture the main display once and detect QR payloads with Vision. Exactly one `otpauth://totp` payload MUST be returned for parsing. Zero or more than one QR payload MUST fail without changing the form, and the form MUST show the reason.

#### Scenario: One QR code

- **WHEN** the capture contains one QR payload
- **THEN** that payload is returned for URI parsing

#### Scenario: No QR code

- **WHEN** the capture contains no QR payload
- **THEN** scanning fails, the form is unchanged, and the reason is shown
