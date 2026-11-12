# Spec Delta

## Purpose

让用户从列表右键复制、重命名和删除账户，并把变更持久化到元数据仓库与密钥库。

## ADDED Requirements

### Requirement: Account context menu

Right-clicking an account row MUST show a context menu with "复制验证码", "复制账号名", a divider, "重命名...", and a destructive "删除账户". "复制账号名" MUST be disabled when the account has no username.

#### Scenario: Menu items

- **WHEN** the user right-clicks an account row
- **THEN** the menu shows "复制验证码", "复制账号名", a divider, "重命名...", and "删除账户", with the destructive style on the last item

#### Scenario: No username

- **WHEN** the account has an empty username
- **THEN** "复制账号名" is disabled

#### Scenario: Copy account name

- **WHEN** the user chooses "复制账号名" for an account with username "ada"
- **THEN** the clipboard contains "ada"

### Requirement: Rename account

"重命名..." MUST prompt for a new display name and prefill the current one. On confirm, the name MUST be split at the first space into site name and username, saved through the metadata repository, and the list MUST refresh. A blank name MUST be rejected without changing the stored record.

#### Scenario: Rename succeeds

- **WHEN** the user renames "GitHub ada" to "GitLab ada"
- **THEN** the metadata record stores site name "GitLab" and username "ada", and the list shows "GitLab ada"

#### Scenario: Blank name rejected

- **WHEN** the user confirms an empty or whitespace-only name
- **THEN** the stored record is unchanged and the list still shows the old name

### Requirement: Delete account

"删除账户" MUST first confirm with the message "确定要删除 [账户名] 吗？此操作不可撤销". On confirm, the secret MUST be deleted from the secret store and the metadata from the repository, then the list MUST refresh. Cancelling MUST leave both stores untouched.

#### Scenario: Confirmed deletion

- **WHEN** the user confirms deletion of an account
- **THEN** its secret is gone from the secret store, its metadata is gone from the repository, and the row disappears

#### Scenario: Cancelled deletion

- **WHEN** the user cancels the confirmation
- **THEN** the secret and metadata remain unchanged
