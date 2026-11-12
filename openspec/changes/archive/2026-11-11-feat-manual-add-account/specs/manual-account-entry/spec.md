# Spec Delta

## Purpose

让用户手动录入一个 TOTP 账户，校验 Base32 Secret，并把账户保存到现有仓库。

## ADDED Requirements

### Requirement: Add account form

The Add command MUST open one entry window. The form MUST contain site name, optional username, secret, algorithm, digits, and period. The initial values MUST be SHA-1, 6 digits, and 30 seconds. The algorithm choices MUST be SHA-1, SHA-256, and SHA-512. The digit choices MUST be 6 and 8.

#### Scenario: Open form

- **WHEN** the user activates Add
- **THEN** one entry window opens with SHA-1, 6 digits, and 30 seconds selected

#### Scenario: Choices

- **WHEN** the user opens the algorithm and digit controls
- **THEN** the algorithm control offers SHA-1, SHA-256, and SHA-512, and the digit control offers 6 and 8

### Requirement: Base32 secret validation

The secret field MUST ignore spaces and hyphens, decode the remaining text as Base32, and reject empty input, characters outside the Base32 alphabet, and invalid padding. A rejected secret MUST NOT be saved.

#### Scenario: Spaces are ignored

- **WHEN** the secret is "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ"
- **THEN** it decodes to the bytes of ASCII "12345678901234567890"

#### Scenario: Invalid character

- **WHEN** the secret contains "1"
- **THEN** validation fails and nothing is saved

#### Scenario: Empty secret

- **WHEN** the secret is empty or only spaces
- **THEN** validation fails and nothing is saved

### Requirement: Save refreshes the list

Saving a valid form MUST write one metadata record and its decoded secret, close the entry window, and show the new account in the menu list. A blank site name MUST NOT be saved. The metadata record MUST NOT contain the secret.

#### Scenario: Valid save

- **WHEN** the user saves site "GitHub", username "ada", a valid secret, SHA-256, 8 digits, and period 30
- **THEN** the repository contains that metadata, the secret store contains the decoded secret, the window closes, and the menu shows "GitHub ada"

#### Scenario: Blank site

- **WHEN** the user saves a blank site name with a valid secret
- **THEN** nothing is saved and the window stays open with the reason
