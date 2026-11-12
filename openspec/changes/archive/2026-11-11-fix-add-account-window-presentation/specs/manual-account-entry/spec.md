# Spec Delta

## MODIFIED Requirements

### Requirement: Add account form

The Add command from either the empty-state button or the footer plus button MUST open one independent entry window. The window MUST be titled "新增 TOTP 账户", include title, close, and minimize controls, appear centered, and stay above normal windows. Opening it MUST activate the app. The form MUST contain one name field, secret, algorithm, digits, and period. The algorithm choices MUST be SHA-1, SHA-256, and SHA-512. The digit choices MUST be 6 and 8.

#### Scenario: Open form

- **WHEN** the user activates either Add control
- **THEN** the app activates and one centered entry window opens with SHA-1, 6 digits, and 30 seconds selected

#### Scenario: Choices

- **WHEN** the user opens the algorithm and digit controls
- **THEN** the algorithm control offers SHA-1, SHA-256, and SHA-512, and the digit control offers 6 and 8

### Requirement: Existing entry window is reused

Activating Add while the entry window is already open MUST bring that same window forward and MUST NOT create another.

#### Scenario: Existing window is reused

- **WHEN** the user activates Add while the entry window is already open
- **THEN** that window comes forward and no second entry window is created

### Requirement: Cancel closes the entry window

Cancel MUST close the entry window without saving an account.

#### Scenario: Cancel closes without saving

- **WHEN** the user activates Cancel
- **THEN** the entry window closes and no account is saved
