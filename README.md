# actions-subtree

Manage all your GitHub Actions workflows across multiple projects.

## Setup

1. Fork this project.
2. FIXME: Run `make prune` to remove all branches other than `main`.
3. Create a PAT and store it as a secret.

### PAT

1. Visit https://github.com/settings/tokens
1. Click "Generate new token"
    - Scope: repo (needed because this is a private repository)
1. Copy generated token
1. Store it as a secret named `TOKEN_KEYS`
