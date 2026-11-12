# totp-core Specification

## Purpose

双端共用的离线 TOTP 规则：RFC 4226 / RFC 6238 计算、otpauth URI 解析、Base32 Secret 校验，以及密钥不得进入文本。macOS 与 Android 客户端都必须遵守。它不约束界面、存储介质或权限。

## Requirements

### Requirement: HOTP codes

The TOTP library MUST compute RFC 4226 HOTP values from raw secret bytes, a non-negative counter, SHA-1, SHA-256, or SHA-512, and a digit count of 6 or 8. It MUST reject an empty secret, a negative counter, and any other digit count by throwing a typed error, without using a force unwrap.

#### Scenario: RFC 4226 SHA-1 vector

- **WHEN** HOTP is computed with the RFC 4226 test secret, SHA-1, 6 digits, and counter 0
- **THEN** the result is `755224`

#### Scenario: SHA-256 and SHA-512

- **WHEN** HOTP is computed for the same secret and counter with SHA-256 and with SHA-512
- **THEN** each result matches the RFC 6238 HOTP value for that hash and is 6 digits

#### Scenario: Eight digits

- **WHEN** HOTP is computed with SHA-1, 8 digits, and counter 0
- **THEN** the result is `84755224`

#### Scenario: Invalid HOTP input

- **WHEN** the secret is empty, the counter is negative, or the digit count is not 6 or 8
- **THEN** computation throws a typed error and returns no code

### Requirement: TOTP codes

The library MUST derive a TOTP counter as `floor(unixTime / period)` and compute it as HOTP. The period MUST be a positive number of seconds and MUST default to 30. It MUST reject a non-positive period by throwing a typed error.

#### Scenario: RFC 6238 timestamp

- **WHEN** TOTP is computed with the RFC 6238 test secret, SHA-1, 8 digits, a 30-second period, and Unix time 59
- **THEN** the result is `94287082`

#### Scenario: Default period

- **WHEN** TOTP is computed at Unix time 59 without an explicit period
- **THEN** the result matches the 30-second-period result for the same secret, hash, and digits

#### Scenario: Later RFC timestamp

- **WHEN** TOTP is computed with SHA-256, 8 digits, a 30-second period, and Unix time 1111111109
- **THEN** the result is `68084774`

#### Scenario: Invalid period

- **WHEN** the period is 0 or negative
- **THEN** computation throws a typed error and returns no code

### Requirement: Secret material stays out of text

Secret material MUST NOT adopt a text-description interface that can include the raw secret. Its text representation MUST NOT contain the secret's raw bytes or their hex or Base32 encoding.

#### Scenario: Description omits the secret

- **WHEN** secret material is interpolated into a string, printed, or inspected through reflection available to app code
- **THEN** the resulting text does not contain the secret bytes or their hex or Base32 encoding

### Requirement: Parse otpauth TOTP URI

The parser MUST accept `otpauth://totp/` URIs. It MUST read `secret`, optional `issuer`, optional label account name, `algorithm`, `digits`, and `period`. Missing algorithm, digits, and period MUST default to SHA-1, 6, and 30. The display name MUST use the issuer and account name when both exist, otherwise the one that exists.

#### Scenario: Full URI

- **WHEN** the URI is `otpauth://totp/GitHub:ada?secret=[密钥]
- **THEN** parsing returns name "GitHub ada", that secret, SHA-256, 8 digits, and period 45

#### Scenario: Defaults

- **WHEN** the URI contains only a secret and label
- **THEN** parsing returns SHA-1, 6 digits, and period 30

### Requirement: Reject unsupported URI values

The parser MUST reject a URI that is not `otpauth://totp`, lacks a secret, or requests an algorithm other than SHA-1, SHA-256, or SHA-512, a digit count other than 6 or 8, or a period below 1.

#### Scenario: Missing secret

- **WHEN** the URI has no secret parameter
- **THEN** parsing fails and returns no fields

#### Scenario: Unsupported algorithm

- **WHEN** the algorithm is `SHA384`
- **THEN** parsing fails and returns no fields

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
