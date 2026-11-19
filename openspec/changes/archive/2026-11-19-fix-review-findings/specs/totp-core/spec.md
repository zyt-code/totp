# Spec Delta

## MODIFIED Requirements

### Requirement: Base32 secret validation

The secret field MUST ignore spaces and hyphens, decode the remaining text as Base32, and reject empty input, characters outside the Base32 alphabet, and invalid padding. A rejected secret MUST NOT be saved.

#### Scenario: Spaces are ignored

- **WHEN** the secret is "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ"
- **THEN** it decodes to the bytes of ASCII "12345678901234567890"

#### Scenario: Invalid character

- **WHEN** the secret contains "1"
- **THEN** validation fails and nothing is saved

#### Scenario: Empty secret

- **WHEN** the secret is empty or only spaces
- **THEN** validation fails and nothing is saved

#### Scenario: Plus is rejected

- **WHEN** the secret contains a literal `+` or a percent-encoded `%2B`
- **THEN** validation fails and nothing is saved

### Requirement: Display name normalization

Both clients MUST derive the displayed title and subtitle with one shared rule. The core MUST split the stored site name at its first colon when that colon is not the first character, otherwise at its first space. The client MUST use a non-empty stored account name as the subtitle and MUST fall back to the split-off part. When every token in the subtitle is the same and there are at least two, the core MUST keep that token once.

#### Scenario: Colon wins

- **WHEN** the stored site name is `OpenAI:me@x.com` and the stored account name is empty
- **THEN** the title is `OpenAI` and the subtitle is `me@x.com`

#### Scenario: Space fallback

- **WHEN** the stored site name is `GitHub ada` and the stored account name is empty
- **THEN** the title is `GitHub` and the subtitle is `ada`

#### Scenario: Repeated account token collapses

- **WHEN** the stored site name is `GitHub:ada ada` and the stored account name is empty
- **THEN** the subtitle is `ada`

#### Scenario: Stored repeated account token collapses

- **WHEN** the stored site name is `GitHub` and the stored account name is `ada ada`
- **THEN** the subtitle is `ada`

#### Scenario: Stored account name is preferred

- **WHEN** the stored site name is `GitHub:ada` and the stored account name is `ada@example.com`
- **THEN** the subtitle is `ada@example.com`
