# Spec Delta

## MODIFIED Requirements

### Requirement: Launch at login

The "登录时自动启动" switch MUST register or unregister the main app with `SMAppService` and MUST show the current registration status when the window opens. A failed registration MUST surface a readable message instead of silently reverting, and reverting the switch to the actual state MUST NOT trigger secondary unregister calls or overwrite the displayed failure message.

#### Scenario: Enabling registers the app

- **WHEN** the user turns on "登录时自动启动"
- **THEN** the app is registered as a login item and the switch stays on

#### Scenario: Status reflects reality

- **WHEN** the settings window opens
- **THEN** the switch reflects the current login-item registration status

#### Scenario: Failure is reported

- **WHEN** registration fails
- **THEN** the window displays a readable message and the switch returns to the actual state without clearing the message
