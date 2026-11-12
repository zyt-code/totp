# Spec Delta

## MODIFIED Requirements

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

### Requirement: Return to menu-bar-only after editing

Opening an editing window, either add-account or settings, MUST make the app a regular app so the window accepts keyboard input and shows a Dock icon. When it closes and no other visible editing window remains, the app MUST return to a menu-bar-only policy so the Dock icon disappears. This MUST hold for cancel, successful save, Escape, and the window close button.

#### Scenario: Window opens

- **WHEN** the user opens an editing window
- **THEN** the app becomes a regular app with a Dock icon and the window accepts typing

#### Scenario: Window closes

- **WHEN** an editing window closes by any supported route
- **THEN** the app returns to menu-bar-only and the Dock icon disappears
