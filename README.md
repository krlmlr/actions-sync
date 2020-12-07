# actions-subtree

Manage all your GitHub Actions workflows across multiple projects.

## Setup

1. Fork this project.
2. FIXME: Run `./run.sh prune` to remove all branches other than `main`.
3. Create a PAT and store it as a secret.

### PAT

1. Visit https://github.com/settings/tokens
1. Click "Generate new token" with scopes:
    - repo (needed because this is a private repository)
    - workflow (needed to change workflows in other repos, implies repo)
1. Copy generated token
1. Store it as a secret named `TOKEN_KEYS`

## Hacking

Code is in `lib/lib.sh`.
Public functions don't start with an underscore and have a comment on the line of the function definition.
This is used for creating the command scripts and for the usage.

### Update command scripts

```sh
./run.sh _make_commands
```
