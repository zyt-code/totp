# backup-export Specification

## Purpose

把账户导出为 otpauth URI 文本备份，便于迁移到其他验证器。导出的文件包含密钥，只写入用户选择的位置。

## Requirements

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
