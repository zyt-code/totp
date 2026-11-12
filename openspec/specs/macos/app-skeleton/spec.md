# app-skeleton Specification

## Purpose

提供一个可启动的 macOS 菜单栏应用壳。它只覆盖启动、退出和状态项外观，不包含账户持久化。验证码计算见 `totp-core`。

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
