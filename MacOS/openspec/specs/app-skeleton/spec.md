# app-skeleton Specification

## Purpose

提供一个可启动的 macOS 菜单栏应用壳，以及与界面解耦、可单独验证的离线 TOTP 计算能力。它只覆盖启动、退出和验证码计算，不包含账户持久化。

## Requirements

### Requirement: Menu bar shell

The app MUST launch as a macOS 14 or newer menu-bar-only process, with no Dock icon. The popover MUST contain the TOTP account list and a footer toolbar with an enabled Add button, an enabled Settings button, and an enabled Quit button. Settings MUST open the settings window and MUST NOT create, import, scan, copy, or persist an account. Add MUST open the manual account entry window.

#### Scenario: Launch shows the placeholder menu

- **WHEN** the app launches
- **THEN** it appears only as a menu-bar item, shows the account list and the footer toolbar, and does not show a Dock icon

#### Scenario: Placeholder items do nothing

- **WHEN** the user activates Settings
- **THEN** no account is created, imported, scanned, copied, or persisted

#### Scenario: Quit ends the process

- **WHEN** the user activates Quit
- **THEN** the app process exits

### Requirement: Status item appearance

The menu-bar status item MUST use a monochrome template symbol so macOS tints it for light and dark menu bars. It MUST NOT use a colored bitmap that ignores menu-bar appearance.

#### Scenario: Symbol shown

- **WHEN** the app launches
- **THEN** the status item shows a lock-with-clock symbol

#### Scenario: Both menu bar appearances

- **WHEN** the menu bar switches between light and dark appearance
- **THEN** the status item stays legible because macOS applies its own tint

### Requirement: Return to menu-bar-only after editing

Opening an editing window, either add-account or settings, MUST make the app a regular app so the window accepts keyboard input and shows a Dock icon. When it closes and no other visible editing window remains, the app MUST return to a menu-bar-only policy so the Dock icon disappears. This MUST hold for cancel, successful save, Escape, and the window close button.

#### Scenario: Window opens

- **WHEN** the user opens the add-account window
- **THEN** the app becomes a regular app with a Dock icon and the window accepts typing

#### Scenario: Window closes

- **WHEN** the add-account window closes by any supported route
- **THEN** the app returns to menu-bar-only and the Dock icon disappears

### Requirement: HOTP codes

The TOTP library MUST compute RFC 4226 HOTP values from raw secret bytes, a non-negative counter, SHA-1, SHA-256, or SHA-512, and a digit count of 6 or 8. It MUST reject an empty secret, a negative counter, and any other digit count by throwing a typed error, without using a force unwrap.

#### Scenario: RFC 4226 SHA-1 vector

- **WHEN** HOTP is computed with the RFC 4226 test secret, SHA-1, 6 digits, and counter 0
- **THEN** the result is `755224`

#### Scenario: SHA-256 and SHA-512

- **WHEN** HOTP is computed for the same secret and counter with SHA-256 and with SHA-512
- **THEN** each result matches the RFC 6238 HOTP value for that hash and is 6 digits

#### Scenario: Eight digits

- **WHEN** HOTP is computed with SHA-1, 8 digits, and counter 0
- **THEN** the result is `84755224`

#### Scenario: Invalid HOTP input

- **WHEN** the secret is empty, the counter is negative, or the digit count is not 6 or 8
- **THEN** computation throws a typed error and returns no code

### Requirement: TOTP codes

The library MUST derive a TOTP counter as `floor(unixTime / period)` and compute it as HOTP. The period MUST be a positive number of seconds and MUST default to 30. It MUST reject a non-positive period by throwing a typed error.

#### Scenario: RFC 6238 timestamp

- **WHEN** TOTP is computed with the RFC 6238 test secret, SHA-1, 8 digits, a 30-second period, and Unix time 59
- **THEN** the result is `94287082`

#### Scenario: Default period

- **WHEN** TOTP is computed at Unix time 59 without an explicit period
- **THEN** the result matches the 30-second-period result for the same secret, hash, and digits

#### Scenario: Later RFC timestamp

- **WHEN** TOTP is computed with SHA-256, 8 digits, a 30-second period, and Unix time 1111111109
- **THEN** the result is `68084774`

#### Scenario: Invalid period

- **WHEN** the period is 0 or negative
- **THEN** computation throws a typed error and returns no code

### Requirement: Secret material stays out of text

Secret material MUST NOT adopt a text-description interface that can include the raw secret. Its text representation MUST NOT contain the secret's raw bytes or their hex or Base32 encoding.

#### Scenario: Description omits the secret

- **WHEN** secret material is interpolated into a string, printed, or inspected through reflection available to app code
- **THEN** the resulting text does not contain the secret bytes or their hex or Base32 encoding
