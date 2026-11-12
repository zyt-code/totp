# Spec Delta

## Purpose

把 TOTP secret 放进 Keychain，把不含 secret 的账户元数据放进本地仓库，并据此组装列表。

## ADDED Requirements

### Requirement: Secret keychain

The secret store MUST add, read, replace, and delete a secret by account id. A read for an unknown id MUST return no secret. A delete for an unknown id MUST leave the store unchanged. Stored secrets MUST NOT appear in text descriptions or metadata.

#### Scenario: Add and read

- **WHEN** a secret is added for an account id
- **THEN** reading that id returns the same bytes

#### Scenario: Replace

- **WHEN** a different secret is saved for an existing account id
- **THEN** reading that id returns only the new bytes

#### Scenario: Delete

- **WHEN** the secret for an account id is deleted
- **THEN** reading that id returns no secret

#### Scenario: Missing id

- **WHEN** an unknown account id is read or deleted
- **THEN** the read returns no secret and the delete changes nothing

### Requirement: Account metadata

The metadata repository MUST save, list, replace, and delete account metadata without a secret. Each record MUST contain the account id, site name, username, algorithm, digit count, and period. Listing MUST preserve insertion order.

#### Scenario: Save and list

- **WHEN** two metadata records are saved
- **THEN** listing returns both, in insertion order, with no secret field

#### Scenario: Replace metadata

- **WHEN** metadata for an existing id is saved again with a new site name
- **THEN** the list contains one record for that id and shows the new site name

#### Scenario: Delete metadata

- **WHEN** a metadata record is deleted
- **THEN** listing no longer contains that id

### Requirement: Assemble stored accounts

Loading accounts MUST pair each metadata record with its Keychain secret and produce one account. A metadata record whose secret is missing MUST be skipped. The resulting account name MUST be the site name followed by the username when a username is present.

#### Scenario: Metadata and secret combine

- **WHEN** metadata and a secret exist for the same id
- **THEN** loading returns one account with that metadata and secret

#### Scenario: Missing secret is skipped

- **WHEN** metadata exists but its secret does not
- **THEN** loading does not return an account for that id

#### Scenario: Display name

- **WHEN** metadata has site name "GitHub" and username "ada"
- **THEN** the loaded account name is "GitHub ada"
