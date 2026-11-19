# Spec Delta

## MODIFIED Requirements

### Requirement: Export otpauth backup

Export MUST ask for confirmation, then write a UTF-8 file the user chooses whose content is the JSON backup document defined by `totp-core`. Each account entry MUST carry the secret, algorithm, digit count, and period. Cancelling MUST write no file.

#### Scenario: Round-trip

- **WHEN** an exported backup is imported
- **THEN** every account returns the same secret, algorithm, digit count, and period as before

#### Scenario: Cancelled export

- **WHEN** the user cancels the confirmation or the save picker
- **THEN** no file is written

### Requirement: Import otpauth backup

Import MUST read a user-chosen file, parse it as the JSON backup document defined by `totp-core`, and save one account per accepted entry. An entry the core rejects MUST be skipped. A file that is not a JSON backup — including the 1.0 line-per-URI text format — MUST be rejected with a message naming the expected format, and MUST save nothing. The result MUST report how many accounts were saved and how many were skipped. Cancelling the picker MUST save nothing.

#### Scenario: Mixed file

- **WHEN** the document has two accepted entries and one whose secret is invalid
- **THEN** two accounts are saved, the invalid entry is skipped, and the result says 2 saved and 1 skipped

#### Scenario: 1.0 text backup is rejected

- **WHEN** the chosen file has one `otpauth://totp` URI per line and is not JSON
- **THEN** nothing is saved and the message names the expected JSON backup format

#### Scenario: Cancelled import

- **WHEN** the user cancels the file picker
- **THEN** no account is saved
