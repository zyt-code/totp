# otpauth-uri Specification

## Purpose

把 `totp-core` 的 otpauth 解析结果填进 macOS 录入表单。解析、默认值和拒绝规则只在 `totp-core`，这里不重复定义。它不截屏，也不保存账户。

## Requirements

### Requirement: Fill the entry form from a parsed URI

The entry form MUST fill its name, secret, algorithm, digits, and period from a URI that `totp-core` accepts. A URI that `totp-core` rejects MUST leave every field unchanged and MUST show the reason.

#### Scenario: Accepted URI fills the form

- **WHEN** the user pastes a URI that `totp-core` parses
- **THEN** the form shows that parse result's name, secret, algorithm, digits, and period

#### Scenario: Rejected URI leaves the form

- **WHEN** the user pastes a URI that `totp-core` rejects
- **THEN** the form fields stay as they were and the reason is shown
