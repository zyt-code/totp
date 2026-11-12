# Spec Delta

## Purpose

规定新增验证码窗口的卡片布局、折叠选项和底部按钮，让录入界面随内容高度变化。

## ADDED Requirements

### Requirement: Add window frame

The add-account window MUST be 380 points wide and MUST size its height to the visible content. Its background MUST use a system material. It MUST show the title "新增验证码" and the subtitle "手动输入或扫描二维码以绑定动态口令".

#### Scenario: Content-sized window

- **WHEN** the add window opens
- **THEN** its width is 380 points and its height fits the collapsed form

#### Scenario: Header copy

- **WHEN** the add window is visible
- **THEN** it shows "新增验证码" and "手动输入或扫描二维码以绑定动态口令"

### Requirement: Entry card

The name and secret fields MUST appear in one rounded card. The name field MUST use the placeholder "例如 github.com 或 [邮箱]". The secret field MUST include a paste button and a disabled screen-scan button. The scan button MUST NOT request screen recording permission or scan the screen.

#### Scenario: Card fields

- **WHEN** the add window opens
- **THEN** the name and secret fields are shown in one rounded card, with paste enabled and screen scan disabled

#### Scenario: Paste fills secret

- **WHEN** the user activates Paste and the clipboard contains text
- **THEN** that text replaces the secret field

### Requirement: Collapsed advanced options

Algorithm, digits, and period MUST be inside a disclosure group titled "高级选项 (算法、位数与周期)". The group MUST be collapsed when the window opens. Expanding it MUST show the existing SHA-1, SHA-256, SHA-512, 6, 8, and period controls.

#### Scenario: Collapsed by default

- **WHEN** the add window opens
- **THEN** the advanced controls are not visible

#### Scenario: Expand options

- **WHEN** the user expands the advanced group
- **THEN** the algorithm, digit, and period controls become visible

### Requirement: Footer actions

The footer MUST right-align a Cancel button and an Add button. Add MUST use the prominent button style. Cancel MUST close the window without saving. Add MUST be disabled while the name is blank or the secret is invalid.

#### Scenario: Invalid form disables Add

- **WHEN** the name is blank or the secret is not valid Base32
- **THEN** the Add button is disabled

#### Scenario: Valid form enables Add

- **WHEN** the name and secret are valid
- **THEN** the Add button is enabled
