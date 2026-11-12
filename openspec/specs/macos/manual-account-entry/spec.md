# manual-account-entry Specification

## Purpose

让用户手动录入一个 TOTP 账户，并保存到现有仓库。Base32 是否合法只按 `totp-core` 判断。录入窗口只负责新增，不包含屏幕扫描或 CSV 导入。

## Requirements

### Requirement: Add account form

The Add command from either the empty-state button or the footer plus button MUST open one independent entry window. The window MUST be titled "新增 TOTP 账户", include title, close, and minimize controls, appear centered, and stay above normal windows. Opening it MUST activate the app and make the window the key window. The form MUST contain one name field, secret, algorithm, digits, and period. The algorithm choices MUST be SHA-1, SHA-256, and SHA-512. The digit choices MUST be 6 and 8.

#### Scenario: Open form

- **WHEN** the user activates either Add control
- **THEN** the app activates and one centered key window opens

#### Scenario: Choices

- **WHEN** the user opens the algorithm and digit controls
- **THEN** the algorithm control offers SHA-1, SHA-256, and SHA-512, and the digit control offers 6 and 8

### Requirement: Name field accepts typing

The name field MUST accept typed text while the entry window is key.

#### Scenario: Name field accepts typing

- **WHEN** the entry window is key and the user types into the name field
- **THEN** the name field shows the typed text

### Requirement: Keyboard submits or cancels

Return MUST submit a valid form, and Escape MUST cancel it without saving.

#### Scenario: Keyboard submits or cancels

- **WHEN** the user presses Return with a valid form or presses Escape
- **THEN** Return saves the form and Escape closes it without saving

### Requirement: Name splits into site and username

The text before the first space MUST be saved as the site name, and the text after it MUST be saved as the optional username. A name without a space MUST leave the username empty.

#### Scenario: Name contains a username

- **WHEN** the user saves the name "GitHub ada"
- **THEN** the stored site name is "GitHub" and the username is "ada"

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

### Requirement: Scan fills the form

A successful screen scan MUST replace the name, secret, algorithm, digits, and period with the parsed URI values. A failed scan MUST leave the current form values unchanged.

#### Scenario: Parsed QR fills fields

- **WHEN** scanning returns a valid otpauth TOTP URI
- **THEN** the form shows that URI's name, secret, algorithm, digits, and period

#### Scenario: Invalid QR keeps the form

- **WHEN** scanning returns a payload that is not a valid otpauth TOTP URI
- **THEN** the form values remain unchanged and the reason is shown

### Requirement: Invalid secret keeps the window open

A secret that `totp-core` rejects MUST NOT be saved. While the secret is non-empty and invalid, the form MUST show one caption-sized red message below the entry card and MUST keep the add window open.

#### Scenario: Invalid character

- **WHEN** the secret contains "1"
- **THEN** a red caption is shown, nothing is saved, and the add window stays open

#### Scenario: Empty secret

- **WHEN** the secret is empty or only spaces
- **THEN** nothing is saved and the add window stays open

### Requirement: Save refreshes the list

Saving a valid form MUST write one metadata record and its decoded secret, close the entry window, and show the new account in the menu list. A blank site name MUST NOT be saved. The metadata record MUST NOT contain the secret.

#### Scenario: Valid save

- **WHEN** the user saves site "GitHub", username "ada", a valid secret, SHA-256, 8 digits, and period 30
- **THEN** the repository contains that metadata, the secret store contains the decoded secret, the window closes, and the menu shows "GitHub ada"

#### Scenario: Blank site

- **WHEN** the user saves a blank site name with a valid secret
- **THEN** nothing is saved and the window stays open with the reason
