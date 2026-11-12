# Spec Delta

## Purpose

规定菜单栏弹窗的尺寸、材质、空状态、账户行和底部工具栏，让明暗模式下都保持可读。

## ADDED Requirements

### Requirement: Popover frame and material

The account popover MUST be 300 points wide and at least 320 points tall. Its background MUST use a system material, a continuous rounded rectangle, and a hairline border. It MUST NOT use an opaque flat gray fill. Text and controls MUST use semantic colors that remain distinguishable in both light and dark mode.

#### Scenario: Fixed frame

- **WHEN** the popover opens
- **THEN** its content width is 300 points and its height is at least 320 points

#### Scenario: Material background

- **WHEN** the popover is shown in either light or dark mode
- **THEN** the background is a system material with a rounded border, not a flat gray fill

### Requirement: Empty state

An empty account list MUST show a centered `lock.badge.clock` symbol, the title "暂无 TOTP 账户", one explanatory subtitle, and a capsule button labeled "添加第一个账户". The button MUST open the existing add-account window and MUST NOT save an account by itself.

#### Scenario: Empty content

- **WHEN** the popover opens with no accounts
- **THEN** the symbol, title, subtitle, and capsule button are centered

#### Scenario: Empty button opens entry

- **WHEN** the user activates "添加第一个账户"
- **THEN** the existing add-account window opens and no account is saved

### Requirement: Account row presentation

Each account row MUST show a monogram badge, the site name, the username when one exists, the current code in monospaced digits, and the remaining-time ring. Hovering MUST add a rounded highlight behind that row. The row MUST remain readable in both light and dark mode.

#### Scenario: Row contents

- **WHEN** an account named "GitHub ada" is shown
- **THEN** the row shows a monogram, "GitHub", "ada", the current code, and the remaining-time ring

#### Scenario: Hover highlight

- **WHEN** the pointer enters a row
- **THEN** that row gains a rounded highlight and the other rows do not

### Requirement: Footer toolbar

The popover MUST end with one horizontal toolbar separated by a divider. The leading side MUST show "共 X 个账户", where X is the loaded account count. The trailing side MUST show a plus button, a disabled gear button, and a power button. The plus button opens the add-account window, the gear button does nothing, and the power button quits the app.

#### Scenario: Footer count

- **WHEN** two accounts are loaded
- **THEN** the footer reads "共 2 个账户"

#### Scenario: Footer actions

- **WHEN** the user activates the plus, gear, or power button
- **THEN** plus opens the add window, gear does nothing, and power quits the app
