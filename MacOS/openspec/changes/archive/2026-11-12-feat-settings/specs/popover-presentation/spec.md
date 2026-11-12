# Spec Delta

## MODIFIED Requirements

### Requirement: Footer toolbar

The popover MUST end with one horizontal toolbar separated by a divider. The leading side MUST show "共 X 个账户", where X is the loaded account count. The trailing side MUST show a plus button, a gear button, and a power button. The plus button opens the add-account window, the gear button opens the settings window, and the power button quits the app.

#### Scenario: Footer count

- **WHEN** two accounts are loaded
- **THEN** the footer reads "共 2 个账户"

#### Scenario: Footer actions

- **WHEN** the user activates the plus, gear, or power button
- **THEN** plus opens the add window, gear opens the settings window, and power quits the app

### Requirement: Grouped code display

A 6-digit code MUST be displayed in two groups of three separated by a space while the grouping preference is enabled. With the preference disabled the code MUST appear as six contiguous digits. Copying MUST always place the ungrouped code in the clipboard.

#### Scenario: Grouped display

- **WHEN** the current code is "404162" and grouping is enabled
- **THEN** the row shows "404 162"

#### Scenario: Grouping disabled

- **WHEN** grouping is disabled
- **THEN** the row shows "404162"

#### Scenario: Clipboard stays ungrouped

- **WHEN** the user copies that row
- **THEN** the clipboard contains "404162"
