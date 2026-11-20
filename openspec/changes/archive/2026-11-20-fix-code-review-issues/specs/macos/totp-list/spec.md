# Spec Delta

## REMOVED Requirements

### Requirement: Display name normalization
**Reason**: Replaced by unified 2.0 totp-core naming rules which do not perform URL decoding at display time.
**Migration**: Use Display name formatting backed by totp-core.

## ADDED Requirements

### Requirement: Display name formatting

Row titles and subtitles MUST be derived following the display name normalization rule defined in `totp-core`: split at the first colon when it is not the first character, otherwise fall back to the first space. A non-empty stored account name MUST be used as subtitle, and repeated tokens in the subtitle MUST be collapsed. Titles and subtitles MUST be trimmed of surrounding whitespace.

#### Scenario: Colon splits title and subtitle

- **WHEN** the stored site name is "OpenAI:ada@example.com" and the username is empty
- **THEN** the row title is "OpenAI" and the subtitle is "ada@example.com"

#### Scenario: Username stays the subtitle

- **WHEN** the stored site name is "GitHub" and the username is "ada"
- **THEN** the row title is "GitHub" and the subtitle is "ada"
