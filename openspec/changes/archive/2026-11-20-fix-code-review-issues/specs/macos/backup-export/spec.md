# Spec Delta

## ADDED Requirements

### Requirement: Import JSON backup

The settings window MUST offer an "导入备份（JSON）" action using an open panel. The chosen file MUST be parsed using the JSON backup format defined by `totp-core`. Valid accounts MUST be saved to Keychain and the metadata repository. Corrupted entries MUST be skipped without stopping valid accounts, and the app MUST report saved and skipped counts in an alert. Invalid file format or version MUST save nothing and display the format error. Cancelling the picker MUST leave all stores untouched.

#### Scenario: Valid JSON backup imports accounts

- **WHEN** the user selects a valid JSON backup containing 2 accounts
- **THEN** both accounts are saved to Keychain and metadata repository, and an alert reports 2 accounts saved

#### Scenario: Corrupted entries are skipped

- **WHEN** the backup contains 2 valid accounts and 1 invalid entry
- **THEN** 2 accounts are saved, 1 is skipped, and an alert reports 2 saved and 1 skipped

#### Scenario: Non-JSON or unsupported version rejected

- **WHEN** the chosen file is not a valid 2.0 JSON backup
- **THEN** no account is saved and an alert shows the format error

#### Scenario: Cancelled import

- **WHEN** the user cancels the file picker
- **THEN** no account is saved and the store remains unchanged
