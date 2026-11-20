# Spec Delta

## MODIFIED Requirements

### Requirement: Rename and delete

A long-press MUST offer rename and delete. Rename MUST split the new name at the first space into site name and username, reject a blank name, and refresh the list. Splitting MUST be strictly by the first space without applying colon-based issuer splitting or token collapsing on the stored fields. Delete MUST confirm, then remove both the secret and the metadata. Cancelling delete MUST leave both stores untouched.

#### Scenario: Rename succeeds

- **WHEN** the user renames "GitHub ada" to "GitLab ada"
- **THEN** the stored site name is "GitLab", the username is "ada", and the card shows "GitLab ada"

#### Scenario: Rename with colon and repeated tokens

- **WHEN** the user renames to "Work:Org ada ada"
- **THEN** the stored site name is "Work:Org" and the stored username is "ada ada"

#### Scenario: Blank rename rejected

- **WHEN** the user submits an empty or whitespace-only name
- **THEN** the stored record is unchanged and the list retains the original name

#### Scenario: Confirmed deletion

- **WHEN** the user confirms deletion
- **THEN** the secret and the metadata for that account are both gone and the card disappears
