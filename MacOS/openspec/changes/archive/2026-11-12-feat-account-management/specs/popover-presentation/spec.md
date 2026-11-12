# Spec Delta

## ADDED Requirements

### Requirement: Uniform single-line rows

The row title and subtitle MUST each render on exactly one line. Overflow MUST truncate, using middle truncation for subtitles and tail truncation for titles. Rows MUST keep the same height regardless of text length.

#### Scenario: Long subtitle

- **WHEN** a row has the subtitle "a.very.long.email.address@example.com"
- **THEN** it stays one line, truncates in the middle, and the row height matches shorter rows

#### Scenario: Long title

- **WHEN** a row title is longer than the available width
- **THEN** it stays one line and truncates at the tail

### Requirement: Expiring code warning

When fewer than or exactly 5 seconds remain in the current period, the row's ring and code MUST switch to a warning color. Above that threshold they MUST use the normal color.

#### Scenario: Warning at five seconds

- **WHEN** a row has 5 seconds or fewer remaining
- **THEN** its ring and code are drawn in the warning color

#### Scenario: Normal above threshold

- **WHEN** a row has more than 5 seconds remaining
- **THEN** its ring and code use the normal color

### Requirement: Grouped code display

A 6-digit code MUST be displayed in two groups of three separated by a space. Copying MUST place the ungrouped code in the clipboard.

#### Scenario: Grouped display

- **WHEN** the current code is "404162"
- **THEN** the row shows "404 162"

#### Scenario: Clipboard stays ungrouped

- **WHEN** the user copies that row
- **THEN** the clipboard contains "404162"
