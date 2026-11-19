# Spec Delta

## MODIFIED Requirements

### Requirement: Secret material stays out of text

Secret material MUST NOT adopt a text-description interface that can include the raw secret. Its text representation MUST NOT contain the secret's raw bytes or their hex or Base32 encoding. Where secret material crosses the shared core boundary inside a parsed model or a result, it MUST travel as raw bytes and MUST NOT be carried in a text field or in a record whose default text form prints every field.

#### Scenario: Description omits the secret

- **WHEN** secret material is interpolated into a string, printed, or inspected through reflection available to app code
- **THEN** the resulting text does not contain the secret bytes or their hex or Base32 encoding

#### Scenario: Boundary record stays redacted

- **WHEN** a record that carries secret bytes is printed, logged, or inspected through reflection available to app code
- **THEN** the resulting text shows no secret bytes, hex encoding, or Base32 encoding

## ADDED Requirements

### Requirement: Display name normalization

Both clients MUST derive the displayed title and subtitle with one shared rule. The core MUST split the stored site name at its first colon when that colon is not the first character, otherwise at its first space. The client MUST use a non-empty stored account name as the subtitle and MUST fall back to the split-off part. When the split-off part repeats the same token two or more times, the core MUST keep that token once.

#### Scenario: Colon wins

- **WHEN** the stored site name is `OpenAI:me@x.com` and the stored account name is empty
- **THEN** the title is `OpenAI` and the subtitle is `me@x.com`

#### Scenario: Space fallback

- **WHEN** the stored site name is `GitHub ada` and the stored account name is empty
- **THEN** the title is `GitHub` and the subtitle is `ada`

#### Scenario: Repeated account token collapses

- **WHEN** the stored site name is `GitHub:ada ada` and the stored account name is empty
- **THEN** the subtitle is `ada`

#### Scenario: Stored account name is preferred

- **WHEN** the stored site name is `GitHub:ada` and the stored account name is `ada@example.com`
- **THEN** the subtitle is `ada@example.com`

### Requirement: JSON backup document

A backup MUST be one JSON object with `format` set to `totp-backup`, an integer `version` set to `2`, and an `accounts` array. Each account MUST carry the site name, account name, Base32 secret, algorithm, digit count, and period.

#### Scenario: Exported document shape

- **WHEN** a backup is exported
- **THEN** the output is one JSON object whose `format` is `totp-backup`, whose `version` is `2`, and whose `accounts` array holds one entry per account

#### Scenario: Round-trip restores every field

- **WHEN** a backup is exported and then imported
- **THEN** every account returns the same site name, account name, secret, algorithm, digit count, and period

### Requirement: Backup import validation

Import MUST reject a document whose `format` or `version` is not the expected value, that is not JSON at all, or that lacks the `accounts` array — saving nothing and returning a format error distinguishable from a skipped account. Import MUST skip accounts that fail the parsing or Base32 rules and MUST report how many were saved and how many were skipped.

#### Scenario: Unknown version is rejected

- **WHEN** the document's `version` is `1`
- **THEN** import saves nothing and returns an error distinguishable from a skipped account

#### Scenario: Line-per-URI text is rejected

- **WHEN** the chosen file is the 1.0 line-per-URI text format
- **THEN** import saves nothing and returns the format error, not a successful import of zero accounts

#### Scenario: Invalid account is skipped

- **WHEN** one account in the document has a secret outside the Base32 alphabet
- **THEN** the remaining accounts are saved and the result reports one skip
