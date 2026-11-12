# settings Specification

## Purpose

提供设置页：控制复制后是否清空剪贴板、验证码是否分段显示、是否允许截屏录屏，以及与 macOS 互通的 `otpauth://` 文本备份导入和导出。

## Requirements

### Requirement: Clipboard auto-clear preference

Auto-clear MUST be enabled by default. Turning it off MUST leave the clipboard untouched after a copy. The setting MUST persist across launches.

#### Scenario: Disabled

- **WHEN** the switch is off and the user copies a code
- **THEN** the app never clears the clipboard because of that copy

### Requirement: Code grouping preference

The grouping switch MUST be enabled by default and MUST persist. The account list MUST follow it on the next frame after it changes.

#### Scenario: Turn grouping off

- **WHEN** the user turns the grouping switch off
- **THEN** cards show contiguous digits and the choice remains after relaunch

### Requirement: Export otpauth backup

Export MUST ask for confirmation, then write a UTF-8 text file the user chooses, with one `otpauth://totp` URI per line. Each URI MUST carry the account secret, algorithm, digit count, and period so `totp-core` parses it back to the same values. Cancelling MUST write no file.

#### Scenario: Round-trip

- **WHEN** an exported URI is parsed by the `totp-core` parser
- **THEN** it yields the same secret, algorithm, digit count, and period as the account

#### Scenario: Cancelled export

- **WHEN** the user cancels the confirmation or the save picker
- **THEN** no file is written

### Requirement: Import otpauth backup

Import MUST read a user-chosen UTF-8 text file and save one account per line that `totp-core` accepts. A line that `totp-core` rejects MUST be skipped. The result MUST report how many accounts were saved and how many lines were skipped. Cancelling the picker MUST save nothing.

#### Scenario: Mixed file

- **WHEN** the file has two accepted URIs and one rejected line
- **THEN** two accounts are saved, the rejected line is skipped, and the result says 2 saved and 1 skipped

### Requirement: Screenshot protection preference

Settings MUST offer "允许截屏与录屏", off by default, so screen capture is blocked unless the user allows it. Turning it on MUST clear `FLAG_SECURE` immediately and turning it off MUST set it again, both without restarting. The choice MUST persist across launches.

#### Scenario: Off by default

- **WHEN** the app is installed and the settings screen is opened
- **THEN** the screenshot switch is off and the window keeps `FLAG_SECURE`

#### Scenario: Turned on takes effect at once

- **WHEN** the user turns the screenshot switch on
- **THEN** the window clears `FLAG_SECURE` while the app stays open
