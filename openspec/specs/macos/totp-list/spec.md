# totp-list Specification

## Purpose

在菜单栏弹窗中显示内存账户的当前验证码、剩余时间，并支持单击复制。账户只存在于进程内存，本能力不写入磁盘或钥匙串。

## Requirements

### Requirement: In-memory account list

The menu MUST render one row per stored account, in repository order, showing each account name. The accounts MUST be loaded from metadata and the secret store, not from a compiled mock list. An empty repository MUST show the centered empty state, including the button that opens the add-account window, and MUST NOT save an account by itself.

#### Scenario: Rows follow the mock accounts

- **WHEN** the menu opens with three stored accounts
- **THEN** it shows three rows in repository order, each with its account name

#### Scenario: Empty list

- **WHEN** the menu opens with no stored accounts
- **THEN** it shows the centered empty state and no account row

#### Scenario: Nothing is persisted

- **WHEN** the app launches with an empty repository
- **THEN** it does not create an account or write a secret

### Requirement: Hover reveals the current code

Each account row MUST always show the account's current TOTP, a ring representing remaining time in the current period, and the remaining whole seconds. Hovering MUST highlight the row without hiding or revealing the code. The code MUST use the account's algorithm and digit count, and MUST change when the period rolls over.

#### Scenario: Hover shows code and countdown

- **WHEN** an account row has 12 whole seconds remaining
- **THEN** the row shows its current TOTP, a ring at 12 divided by the account period, and the number 12 before the pointer enters

#### Scenario: Pointer leaves

- **WHEN** the pointer leaves the row
- **THEN** the highlight disappears and the current TOTP remains visible

#### Scenario: Period rolls over

- **WHEN** the pointer remains over the row and the period ends
- **THEN** the row shows the next TOTP and the remaining seconds restart from the new period

### Requirement: Load accounts before first render

The menu MUST load stored accounts before its first render, so opening the popover never flashes the empty state while rows exist. A repository containing accounts MUST show those rows on the first frame; only an actually empty repository MAY show the empty state.

#### Scenario: First open shows rows

- **WHEN** the popover is opened with three stored accounts
- **THEN** the first frame already shows three rows and never shows the empty state

#### Scenario: Empty repository still shows the empty state

- **WHEN** the popover is opened with no stored accounts
- **THEN** it shows the empty state on the first frame

### Requirement: Click copies the code

Clicking anywhere on an account row MUST copy that row's current TOTP to the system clipboard and show a copied confirmation on the row. The confirmation MUST clear within 2 seconds. When auto-clear is enabled, the app MUST clear the clipboard after the configured delay if it still contains that same code.

#### Scenario: Click copies and confirms

- **WHEN** the user clicks any part of an account row
- **THEN** the clipboard contains that row's current TOTP and the row shows a copied confirmation

#### Scenario: Confirmation expires

- **WHEN** 2 seconds pass after the confirmation appears
- **THEN** the confirmation is no longer visible

#### Scenario: Clipboard is cleared

- **WHEN** the configured auto-clear delay passes after copying and the clipboard still contains that TOTP
- **THEN** the clipboard no longer contains it

#### Scenario: Clipboard changed by the user

- **WHEN** the user replaces the clipboard before the clear time
- **THEN** the app leaves the replacement in place

### Requirement: Display name normalization

Row titles MUST decode URL-encoded text: `+` becomes a space and percent escapes are resolved. When the title contains a colon and no subtitle exists, the text MUST split at the first colon into title and subtitle. Titles and subtitles MUST be trimmed of surrounding whitespace.

#### Scenario: Plus decoded as space

- **WHEN** the stored site name is "Spot+Auth+Lab"
- **THEN** the row title is "Spot Auth Lab"

#### Scenario: Percent escapes resolved

- **WHEN** the stored site name is "Spot%20Auth"
- **THEN** the row title is "Spot Auth"

#### Scenario: Colon splits title and subtitle

- **WHEN** the stored site name is "OpenAI:ada@example.com" and the username is empty
- **THEN** the row title is "OpenAI" and the subtitle is "ada@example.com"

#### Scenario: Username stays the subtitle

- **WHEN** the stored site name is "GitHub" and the username is "ada"
- **THEN** the row title is "GitHub" and the subtitle is "ada"
