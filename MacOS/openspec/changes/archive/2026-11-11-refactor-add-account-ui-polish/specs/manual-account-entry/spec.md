# Spec Delta

## MODIFIED Requirements

### Requirement: Add account form

The Add command from either the empty-state button or the footer plus button MUST open one independent entry window. The window MUST be titled "新增 TOTP 账户", include title, close, and minimize controls, appear centered, and stay above normal windows. Opening it MUST activate the app. Activating Add while the window already exists MUST bring that same window forward and MUST NOT create another. The form MUST contain one name field, secret, algorithm, digits, and period. The initial values MUST be SHA-1, 6 digits, and 30 seconds. The algorithm choices MUST be SHA-1, SHA-256, and SHA-512. The digit choices MUST be 6 and 8. The text before the first space is the site name, and the text after it is the optional username. Cancel MUST close the window without saving.

#### Scenario: Open form

- **WHEN** the user activates either Add control
- **THEN** the app activates and one centered entry window opens with SHA-1, 6 digits, and 30 seconds selected

#### Scenario: Choices

- **WHEN** the user opens the algorithm and digit controls
- **THEN** the algorithm control offers SHA-1, SHA-256, and SHA-512, and the digit control offers 6 and 8

#### Scenario: Existing window is reused

- **WHEN** the user activates Add while the entry window is already open
- **THEN** that window comes forward and no second entry window is created

#### Scenario: Cancel closes without saving

- **WHEN** the user activates Cancel
- **THEN** the entry window closes and no account is saved

### Requirement: Base32 secret validation

The secret field MUST ignore spaces and hyphens, decode the remaining text as Base32, and reject empty input, characters outside the Base32 alphabet, and invalid padding. A rejected secret MUST NOT be saved. While the secret is non-empty and invalid, the form MUST show one caption-sized red message below the entry card without closing the window.

#### Scenario: Spaces are ignored

- **WHEN** the secret is "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ"
- **THEN** it decodes to the bytes of ASCII "12345678901234567890"

#### Scenario: Invalid character

- **WHEN** the secret contains "1"
- **THEN** validation fails, a red caption is shown, and nothing is saved

#### Scenario: Empty secret

- **WHEN** the secret is empty or only spaces
- **THEN** validation fails and nothing is saved
