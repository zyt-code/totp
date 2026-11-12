# Spec Delta

## ADDED Requirements

### Requirement: Status item appearance

The menu-bar status item MUST use a monochrome template symbol so macOS tints it for light and dark menu bars. It MUST NOT use a colored bitmap that ignores menu-bar appearance.

#### Scenario: Symbol shown

- **WHEN** the app launches
- **THEN** the status item shows a lock-with-clock symbol

#### Scenario: Both menu bar appearances

- **WHEN** the menu bar switches between light and dark appearance
- **THEN** the status item stays legible because macOS applies its own tint

### Requirement: Return to menu-bar-only after editing

Opening the add-account window MUST make the app a regular app so the window accepts keyboard input and shows a Dock icon. When that window closes, and no other visible editing window remains, the app MUST return to a menu-bar-only policy so the Dock icon disappears. This MUST hold for cancel, successful save, Escape, and the window close button.

#### Scenario: Window opens

- **WHEN** the user opens the add-account window
- **THEN** the app becomes a regular app with a Dock icon and the window accepts typing

#### Scenario: Window closes

- **WHEN** the add-account window closes by any supported route
- **THEN** the app returns to menu-bar-only and the Dock icon disappears
