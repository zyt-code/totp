# Spec Delta

## MODIFIED Requirements

### Requirement: In-memory account list

The menu MUST render one row per stored account, in repository order, showing each account name. The accounts MUST be loaded from metadata and the secret store, not from a compiled mock list. An empty repository MUST show one non-interactive empty state instead of account rows.

#### Scenario: Rows follow the mock accounts

- **WHEN** the menu opens with three stored accounts
- **THEN** it shows three rows in repository order, each with its account name

#### Scenario: Empty list

- **WHEN** the menu opens with no stored accounts
- **THEN** it shows an empty state and no account row

#### Scenario: Nothing is persisted

- **WHEN** the app launches with an empty repository
- **THEN** it does not create an account or write a secret
