# Spec Delta

## Purpose

在菜单栏弹窗中显示内存账户的当前验证码、剩余时间，并支持单击复制。

## ADDED Requirements

### Requirement: In-memory account list

The menu MUST render one row per in-memory account, in the supplied order, showing each account name. The accounts MUST exist only in process memory and MUST NOT be written to disk or Keychain. An empty account list MUST show one non-interactive empty state instead of account rows.

#### Scenario: Rows follow the mock accounts

- **WHEN** the menu opens with three in-memory accounts
- **THEN** it shows three rows in that order, each with its account name

#### Scenario: Empty list

- **WHEN** the menu opens with no accounts
- **THEN** it shows an empty state and no account row

#### Scenario: Nothing is persisted

- **WHEN** the app launches and later quits
- **THEN** no account or secret is written to disk or Keychain

### Requirement: Hover reveals the current code

While the pointer is over an account row, that row MUST show the account's current TOTP, a ring representing remaining time in the current period, and the remaining whole seconds. The code MUST be hidden when the pointer is not over the row. The code MUST use the account's algorithm and digit count, and MUST change when the period rolls over.

#### Scenario: Hover shows code and countdown

- **WHEN** the pointer enters an account row with 12 whole seconds remaining
- **THEN** the row shows its current TOTP, a ring at 12 divided by the account period, and the number 12

#### Scenario: Pointer leaves

- **WHEN** the pointer leaves the row
- **THEN** the TOTP is no longer visible

#### Scenario: Period rolls over

- **WHEN** the pointer remains over the row and the period ends
- **THEN** the row shows the next TOTP and the remaining seconds restart from the new period

### Requirement: Click copies the code

Clicking anywhere on an account row MUST copy that row's current TOTP to the system clipboard and show a copied confirmation on the row. The confirmation MUST clear within 2 seconds. If the clipboard still contains that same code about 30 seconds later, the app MUST clear it.

#### Scenario: Click copies and confirms

- **WHEN** the user clicks any part of an account row
- **THEN** the clipboard contains that row's current TOTP and the row shows a copied confirmation

#### Scenario: Confirmation expires

- **WHEN** 2 seconds pass after the confirmation appears
- **THEN** the confirmation is no longer visible

#### Scenario: Clipboard is cleared

- **WHEN** about 30 seconds pass after copying and the clipboard still contains that TOTP
- **THEN** the clipboard no longer contains it

#### Scenario: Clipboard changed by the user

- **WHEN** the user replaces the clipboard before the clear time
- **THEN** the app leaves the replacement in place
