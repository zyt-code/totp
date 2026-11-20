# Spec Delta

## MODIFIED Requirements

### Requirement: Camera scan saves one account

The add flow MUST offer a live camera scan and MUST NOT offer a manual entry form. When the camera reads exactly one URI that `totp-core` accepts, the app MUST vibrate once, save that account exactly once, and return to the list. Subsequent frames from the camera feed MUST be ignored once a valid code is detected, preventing duplicate saves. Zero matches, more than one match, or a URI that `totp-core` rejects MUST save nothing and leave the scan screen open.

#### Scenario: One valid code

- **WHEN** the camera reads one `otpauth://totp/` URI that `totp-core` accepts
- **THEN** the device vibrates once, the account is saved, and the list is shown

#### Scenario: Consecutive frames debounce duplicate saves

- **WHEN** the camera continuously streams frames containing the same valid `otpauth://totp/` URI
- **THEN** the account is saved only once and the device vibrates only once before navigating back

#### Scenario: Invalid payload

- **WHEN** the camera reads a payload that `totp-core` rejects
- **THEN** nothing is saved and the scan screen stays open

### Requirement: Gallery pick saves one account

The scan screen MUST offer picking one image with the system photo picker, without requesting storage permission. One accepted URI MUST save the account and return to the list. Any other result MUST save nothing and show a Material 3 snackbar with the reason visible on the scan screen.

#### Scenario: Valid image

- **WHEN** the picked image contains one URI that `totp-core` accepts
- **THEN** the account is saved and the list is shown

#### Scenario: Invalid image

- **WHEN** the picked image has no accepted `otpauth://totp/` URI
- **THEN** nothing is saved and a snackbar on the scan screen shows the reason
