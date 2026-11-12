# account-list Specification

## Purpose

在首页用卡片列出已保存账户的当前验证码和剩余时间，并支持搜索、复制、重命名和删除。验证码计算遵守 `totp-core`。

## Requirements

### Requirement: Account cards

The home screen MUST show one card per stored account, in repository order. Each card MUST show a circular initial badge, the site name and username each on one line with middle ellipsis when they overflow, the current code in large monospaced digits, and a ring for the remaining fraction of the period. An empty repository MUST show an empty state and an add action, and MUST NOT create an account by itself.

#### Scenario: Rows follow stored accounts

- **WHEN** the home screen opens with two stored accounts
- **THEN** it shows two cards in repository order, each with its badge, names, current code, and ring

#### Scenario: Empty list

- **WHEN** the home screen opens with no stored accounts
- **THEN** it shows the empty state and no account card

### Requirement: Expiring code warning

When 5 or fewer whole seconds remain in the period, the ring and the code MUST use the warning color. Above that they MUST use the normal color. The color change MUST animate.

#### Scenario: Five seconds left

- **WHEN** a card has 5 whole seconds remaining
- **THEN** its ring and code are shown in the warning color

### Requirement: Copy clears after 30 seconds

Tapping a card MUST copy that card's current ungrouped code to the clipboard. The card MUST confirm the copy by replacing the code with "已复制" for about 1.2 seconds, then show the code again. When auto-clear is enabled, the app MUST clear the clipboard after 30 seconds only if it still contains that same code.

#### Scenario: Copy shows confirmation

- **WHEN** the user taps a card
- **THEN** the card shows "已复制" instead of the code and returns to the code within about 1.2 seconds

#### Scenario: Matching clipboard is cleared

- **WHEN** 30 seconds pass after a tap and the clipboard still holds that code
- **THEN** the clipboard is cleared

#### Scenario: Replaced clipboard is kept

- **WHEN** the user copies something else before 30 seconds pass
- **THEN** the app leaves that content in place

### Requirement: Grouped code display

While the grouping preference is enabled, a 6-digit code MUST be shown as two groups of three separated by a space. Copying MUST still place the ungrouped digits on the clipboard. With grouping disabled the card MUST show contiguous digits.

#### Scenario: Grouped display, plain copy

- **WHEN** the code is `404162` and grouping is enabled and the user taps the card
- **THEN** the card shows `404 162` and the clipboard contains `404162`

### Requirement: Rename and delete

A long-press MUST offer rename and delete. Rename MUST split the new name at the first space into site name and username, reject a blank name, and refresh the list. Delete MUST confirm, then remove both the secret and the metadata. Cancelling delete MUST leave both stores unchanged.

#### Scenario: Rename succeeds

- **WHEN** the user renames "GitHub ada" to "GitLab ada"
- **THEN** the stored site name is "GitLab", the username is "ada", and the card shows "GitLab ada"

#### Scenario: Confirmed deletion

- **WHEN** the user confirms deletion
- **THEN** the secret and the metadata for that account are both gone and the card disappears

### Requirement: Search accounts

The home screen MUST offer a search mode that filters cards by site name or username, ignoring case. Pulling down at the top of the list by at least 64 dp MUST open search mode, focus the field, and show the keyboard. System back MUST close search mode instead of leaving the app. Closing search MUST clear the query.

#### Scenario: Typing filters the list

- **WHEN** the user types "git" in search mode
- **THEN** only cards whose site name or username contains "git" remain

#### Scenario: Pull down opens search

- **WHEN** the list is scrolled to the top and the user drags down by at least 64 dp
- **THEN** search mode opens with the field focused and the keyboard shown

#### Scenario: Back closes search first

- **WHEN** search mode is open and the user presses back
- **THEN** the query is cleared, search mode closes, and the app stays open

### Requirement: Add action opens the scanner

The home screen's add button MUST open the camera scan screen directly, with no intermediate menu.

#### Scenario: Tap add

- **WHEN** the user taps the add button
- **THEN** the camera scan screen opens
