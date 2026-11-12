# Spec Delta

## MODIFIED Requirements

### Requirement: Add account form

The Add command from either the empty-state button or the footer plus button MUST open one independent entry window. The window MUST be titled "新增 TOTP 账户", include title, close, and minimize controls, appear centered, and stay above normal windows. Opening it MUST activate the app and make the window the key window. The name field MUST be able to receive typing. Return MUST submit a valid form, and Escape MUST cancel it. The form MUST contain one name field, secret, algorithm, digits, and period. The algorithm choices MUST be SHA-1, SHA-256, and SHA-512. The digit choices MUST be 6 and 8.

#### Scenario: Open form

- **WHEN** the user activates either Add control
- **THEN** the app activates, one centered key window opens, and the name field accepts typed text

#### Scenario: Choices

- **WHEN** the user opens the algorithm and digit controls
- **THEN** the algorithm control offers SHA-1, SHA-256, and SHA-512, and the digit control offers 6 and 8

#### Scenario: Keyboard submits or cancels

- **WHEN** the user presses Return with a valid form or presses Escape
- **THEN** Return saves the form and Escape closes it without saving

## ADDED Requirements

### Requirement: Scan fills the form

A successful screen scan MUST replace the name, secret, algorithm, digits, and period with the parsed URI values. A failed scan MUST leave the current form values unchanged.

#### Scenario: Parsed QR fills fields

- **WHEN** scanning returns a valid otpauth TOTP URI
- **THEN** the form shows that URI's name, secret, algorithm, digits, and period

#### Scenario: Invalid QR keeps the form

- **WHEN** scanning returns a payload that is not a valid otpauth TOTP URI
- **THEN** the form values remain unchanged and the reason is shown
