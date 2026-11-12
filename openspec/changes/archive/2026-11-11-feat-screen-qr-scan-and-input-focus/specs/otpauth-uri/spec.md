# Spec Delta

## Purpose

解析标准 otpauth TOTP URI，供手动录入表单填充名称、Secret 和高级选项。

## ADDED Requirements

### Requirement: Parse otpauth TOTP URI

The parser MUST accept `otpauth://totp/` URIs. It MUST read `secret`, optional `issuer`, optional label account name, `algorithm`, `digits`, and `period`. Missing algorithm, digits, and period MUST default to SHA-1, 6, and 30. The display name MUST use the issuer and account name when both exist, otherwise the one that exists.

#### Scenario: Full URI

- **WHEN** the URI is `otpauth://totp/GitHub:ada?secret=GEZDGNBV&issuer=GitHub&algorithm=SHA256&digits=8&period=45`
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
