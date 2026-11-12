# Spec Delta

## MODIFIED Requirements

### Requirement: Menu bar shell

The app MUST launch as a macOS 14 or newer menu-bar-only process, with no Dock icon. The popover MUST contain the TOTP account list and a footer toolbar with an enabled Add button, a disabled Settings button, and an enabled Quit button. Settings MUST NOT create, import, scan, copy, or persist an account. Add MUST open the manual account entry window.

#### Scenario: Launch shows the placeholder menu

- **WHEN** the app launches
- **THEN** it appears only as a menu-bar item, shows the account list and the footer toolbar, and does not show a Dock icon

#### Scenario: Placeholder items do nothing

- **WHEN** the user activates Settings
- **THEN** no account is created, imported, scanned, copied, or persisted

#### Scenario: Quit ends the process

- **WHEN** the user activates Quit
- **THEN** the app process exits
