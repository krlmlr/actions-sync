# actions-subtree

Manage all your GitHub Actions workflows across multiple projects.
Synchronize to and from all your projects.
Apply changes at once across all your projects.

## Setup

1. Fork this project.
1. Make private if needed.
1. Clone it locally.
1. Remove all branches other than `main` in your fork:

    ```sh
    git branch -r | grep " origin/" | grep -v /main | sed -r 's#^ +([^/]+)/(.*)$#git push \1 :\2#' | sh
    ```

1. Create a PAT and store it as a secret.
    1. Visit <https://github.com/settings/tokens>
    1. Click "Generate new token" with scopes:
        - repo (needed because this is a private repository)
        - workflow (needed to change workflows in other repos, implies repo)
    1. Copy generated token
    1. Store it as a secret named `TOKEN_KEYS`

## Design

Branches in this repository correspond to projects (*remote repositories*) on GitHub.
Each branch here contains the history of `.github/workflows` in the corresponding remote repository.
Existing projects can be imported with their history.
Projects that don't have GitHub Actions yet can inherit from an existing project by creating a new branch in this repository from an existing branch.

From then on, pushes to this repository apply the new commits to the remote repository, with a technique similar to `git subtree`, hence the name.
Backwards synchronization happens on schedule and is a variant of the initial import.

Branches that start with `main` are special.
Also, branches that don't have a slash in their name are not synchronized with repositories.

> Example: I maintain [r-dbi/DBI](https://github.com/r-dbi/DBI), [r-dbi/RKazam](https://github.com/r-dbi/RKazam) and [r-lib/rprojroot](https://github.com/r-lib/rprojroot), among other projects.
> This repository has branches:
>
> - [r-dbi/DBI](https://github.com/krlmlr/actions-subtree/tree/r-dbi/DBI)
> - [r-dbi/RKazam](https://github.com/krlmlr/actions-subtree/tree/r-dbi/RKazam)
> - [r-lib/rprojroot](https://github.com/krlmlr/actions-subtree/tree/r-lib/rprojroot)
> - ...
>
> The top level of the latter three branches contain the `.yaml` files from the `.github/workflows` directory in the remote repositories.
> It also contains its own `.github` directory that powers the synchronization but is not copied to the remote repository.


## Basic workflow

1. Import a project, one of:
    1. Trigger the ["Import/refresh remote repositories" action](https://github.com/krlmlr/actions-subtree/actions?query=workflow%3A%22Import%2Frefresh+remote+repositories%22): click "Run workflow", enter the owner/repo of the repository you want to import
    1. `bin/import owner/repo`
1. Copy the setup for an existing *base* project to a new project, one of:
    1. Trigger the ["Import/refresh remote repositories" action](https://github.com/krlmlr/actions-subtree/actions?query=workflow%3A%22Import%2Frefresh+remote+repositories%22): click "Run workflow", enter the owner/repo of the repository you want to import and the name of the base owner/repo of the boilerplate repository
    1. `bin/import_base owner/repo base-owner/base-repo`
1. Synchronization from this repository to the remote repositories:
    - automatically via GitHub Actions, on push
    - there is also a manual ways but tihs will bork your work trees
1. Synchronization from the remote repositories to this repositories, one of:
    - automatically via GitHub Actions, on schedule or triggered
    - there is also a manual ways but tihs will bork your work trees


## Editing workflows locally

Tested on Ubuntu.
Requires GNU `parallel`.

1. Extract all branches as worktrees locally, to the `wt/` directory:
    - `bin/add_worktrees`
1. Apply a Git command to all worktrees:
    - Fast-forward pull all worktrees:

        ```sh
        bin/wt_pull
        ```

    - Rebase all worktrees:

        ```sh
        git fetch
        bin/wt_git rebase
        ```

    - Show status for all worktrees:

        ```sh
        bin/wt_git status
        ```

    - Apply the last commit of the `foo` branch to all other branches:

        ```sh
        bin/wt_git cherry-pick owner/repo
        ```

    - Copy over `workflow.yaml` from the `foo` branch to all other branches:

        ```sh
        bin/wt_git checkout -f foo -- workflow.yaml
        ```

    - Copy over the contents of the `foo` branch to all other branches:

        ```sh
        bin/wt_copy_to base-branch
        ```

    - Show diff for all worktrees:

        ```sh
        bin/wt_git diff
        ```

    - Commit all worktrees:

        ```sh
        bin/wt_git commit -m "My commit message"
        ```

1. Push all worktrees:
    - `git push --all`
    - Add `-n` to verify what happens
    - After push to this repository, the contents are synchronized with the remote repository by GitHub Actions
1. Clean up all worktrees
    - `bin/remove_worktrees`


## Hacking

Code is in `lib/lib.sh`.
Public functions don't start with an underscore and have a comment on the line of the function definition.
This is used for creating the command scripts and for the usage.

### Update command scripts

```sh
./run.sh _make_commands
```
