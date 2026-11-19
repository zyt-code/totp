# Spec Delta

## MODIFIED Requirements

### Requirement: Export otpauth backup

The export action MUST ask for confirmation, then use a save panel to write a UTF-8 file whose content is the JSON backup document defined by `totp-core`. Each account entry MUST carry the secret, algorithm, digit count, and period so importing the file restores the same values. Cancelling the confirmation or the save panel MUST write no file.

#### Scenario: Confirmed export writes a file

- **WHEN** the user confirms the export and picks a destination
- **THEN** the file is one JSON object with `format` `totp-backup`, `version` `2`, and one entry per account

#### Scenario: Cancelled export writes nothing

- **WHEN** the user cancels the confirmation or the save panel
- **THEN** no file is written

#### Scenario: Exported URI round-trips

- **WHEN** an exported file is imported back
- **THEN** every account returns the same secret, algorithm, digit count, and period as before
