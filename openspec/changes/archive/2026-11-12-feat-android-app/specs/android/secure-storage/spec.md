# Spec Delta

## Purpose

把 TOTP 密钥加密后保存，把不含密钥的账户元数据放进本地数据库，并按账户 id 组装成可用账户。它不规定界面。

## ADDED Requirements

### Requirement: Encrypted secret store

Each secret MUST be encrypted with a key that never leaves the Android Keystore, using AES-256-GCM, before it is written. The store MUST add, read, replace, and delete a secret by account id. A read or delete for an unknown id MUST change nothing and return no secret. Stored secrets MUST NOT appear in text descriptions, logs, or metadata.

#### Scenario: Add and read

- **WHEN** a secret is added for an account id
- **THEN** reading that id returns the same bytes, and the bytes on disk are not the plaintext secret

#### Scenario: Missing id

- **WHEN** an unknown account id is read or deleted
- **THEN** the read returns no secret and the delete changes nothing

### Requirement: Account metadata

The metadata store MUST save, list, replace, and delete account metadata without a secret. Each record MUST contain the account id, site name, username, algorithm, digit count, and period. Listing MUST preserve insertion order.

#### Scenario: Save and list

- **WHEN** two metadata records are saved
- **THEN** listing returns both, in insertion order, with no secret field

### Requirement: Assemble stored accounts

Loading accounts MUST pair each metadata record with its decrypted secret. A metadata record whose secret is missing MUST be skipped. The display name MUST be the site name followed by the username when a username is present.

#### Scenario: Missing secret is skipped

- **WHEN** metadata exists but its secret does not
- **THEN** loading does not return an account for that id
