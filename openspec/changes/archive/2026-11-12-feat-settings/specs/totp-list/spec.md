# Spec Delta

## ADDED Requirements

### Requirement: Load accounts before first render

The menu MUST load stored accounts before its first render, so opening the popover never flashes the empty state while rows exist. A repository containing accounts MUST show those rows on the first frame; only an actually empty repository MAY show the empty state.

#### Scenario: First open shows rows

- **WHEN** the popover is opened with three stored accounts
- **THEN** the first frame already shows three rows and never shows the empty state

#### Scenario: Empty repository still shows the empty state

- **WHEN** the popover is opened with no stored accounts
- **THEN** it shows the empty state on the first frame

## MODIFIED Requirements

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
