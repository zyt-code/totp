# Spec Delta

## MODIFIED Requirements

### Requirement: Menu bar shell

The app MUST launch as a macOS 14 or newer menu-bar-only process, with no Dock icon, and MUST expose a menu containing the TOTP account list, a separator, a disabled Add item, a disabled Settings item, and an enabled Quit item. Add and Settings MUST NOT create, import, scan, copy, or persist an account.

#### Scenario: Launch shows the placeholder menu

- **WHEN** the app launches
- **THEN** it appears only as a menu-bar item, shows the account list followed by a separator, Add, Settings, and Quit, and does not show a Dock icon

#### Scenario: Placeholder items do nothing

- **WHEN** the user activates Add or Settings
- **THEN** no account is created, imported, scanned, copied, or persisted

#### Scenario: Quit ends the process

- **WHEN** the user activates Quit
- **THEN** the app process exits
