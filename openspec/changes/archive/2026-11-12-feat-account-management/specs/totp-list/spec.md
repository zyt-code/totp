# Spec Delta

## ADDED Requirements

### Requirement: Display name normalization

Row titles MUST decode URL-encoded text: `+` becomes a space and percent escapes are resolved. When the title contains a colon and no subtitle exists, the text MUST split at the first colon into title and subtitle. Titles and subtitles MUST be trimmed of surrounding whitespace.

#### Scenario: Plus decoded as space

- **WHEN** the stored site name is "Spot+Auth+Lab"
- **THEN** the row title is "Spot Auth Lab"

#### Scenario: Percent escapes resolved

- **WHEN** the stored site name is "Spot%20Auth"
- **THEN** the row title is "Spot Auth"

#### Scenario: Colon splits title and subtitle

- **WHEN** the stored site name is "OpenAI:ada@example.com" and the username is empty
- **THEN** the row title is "OpenAI" and the subtitle is "ada@example.com"

#### Scenario: Username stays the subtitle

- **WHEN** the stored site name is "GitHub" and the username is "ada"
- **THEN** the row title is "GitHub" and the subtitle is "ada"
