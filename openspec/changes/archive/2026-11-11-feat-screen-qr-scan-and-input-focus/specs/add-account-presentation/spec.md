# Spec Delta

## MODIFIED Requirements

### Requirement: Entry card

The name and secret fields MUST appear in one rounded card. The name field MUST use the placeholder "例如 github.com 或 [邮箱]". The secret field MUST include a paste button and an enabled screen-scan button. The scan button MUST start the screen QR scan flow.

#### Scenario: Card fields

- **WHEN** the add window opens
- **THEN** the name and secret fields are shown in one rounded card, with paste and screen scan enabled

#### Scenario: Paste fills secret

- **WHEN** the user activates Paste and the clipboard contains text
- **THEN** that text replaces the secret field

#### Scenario: Scan starts from the card

- **WHEN** the user activates the screen-scan button
- **THEN** the screen QR scan flow starts
