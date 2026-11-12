# Spec Delta

## MODIFIED Requirements

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

- **WHEN** the period ends while the row is visible
- **THEN** the row shows the next TOTP and the remaining seconds restart from the new period
