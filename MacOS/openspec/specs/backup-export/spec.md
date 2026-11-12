# backup-export Specification

## Purpose

把账户导出为 otpauth URI 文本备份，便于迁移到其他验证器。导出的文件包含密钥，只写入用户选择的位置。

## Requirements

### Requirement: Export otpauth backup

The export action MUST ask for confirmation, then use a save panel to write a UTF-8 text file with one `otpauth://totp` URI per line. Each URI MUST carry the account's secret, algorithm, digit count, and period so it parses back to the same values. Cancelling the confirmation or the save panel MUST write no file.

#### Scenario: Confirmed export writes a file

- **WHEN** the user confirms the export and picks a destination
- **THEN** the file contains one otpauth URI per account, separated by newlines

#### Scenario: Cancelled export writes nothing

- **WHEN** the user cancels the confirmation or the save panel
- **THEN** no file is written

#### Scenario: Exported URI round-trips

- **WHEN** an exported URI is parsed by the otpauth parser
- **THEN** it yields the same secret, algorithm, digit count, and period as the account
