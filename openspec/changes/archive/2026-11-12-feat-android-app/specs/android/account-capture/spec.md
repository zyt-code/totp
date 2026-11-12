# Spec Delta

## Purpose

用相机或相册里的二维码新增账户。只接受 `totp-core` 判定合法的 `otpauth://totp/` URI，没有手动填写表单。

## ADDED Requirements

### Requirement: Camera scan saves one account

The add flow MUST offer a live camera scan and MUST NOT offer a manual entry form. When the camera reads exactly one URI that `totp-core` accepts, the app MUST vibrate once, save that account, and return to the list. Zero matches, more than one match, or a URI that `totp-core` rejects MUST save nothing and leave the scan screen open.

#### Scenario: One valid code

- **WHEN** the camera reads one `otpauth://totp/` URI that `totp-core` accepts
- **THEN** the device vibrates once, the account is saved, and the list is shown

#### Scenario: Invalid payload

- **WHEN** the camera reads a payload that `totp-core` rejects
- **THEN** nothing is saved and the scan screen stays open

### Requirement: Gallery pick saves one account

The scan screen MUST offer picking one image with the system photo picker, without requesting storage permission. One accepted URI MUST save the account and return to the list. Any other result MUST save nothing and show a Material 3 snackbar with the reason.

#### Scenario: Valid image

- **WHEN** the picked image contains one URI that `totp-core` accepts
- **THEN** the account is saved and the list is shown

#### Scenario: Invalid image

- **WHEN** the picked image has no accepted `otpauth://totp/` URI
- **THEN** nothing is saved and a snackbar shows the reason

### Requirement: Camera permission

Starting a camera scan without camera permission MUST ask for it. If the user denies it, the app MUST NOT open the camera and MUST still allow the gallery pick.

#### Scenario: Permission denied

- **WHEN** the user denies camera permission
- **THEN** the camera does not open and the gallery pick remains available
