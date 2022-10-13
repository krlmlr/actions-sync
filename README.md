# [actions-sync](https://krlmlr.github.io/actions-sync)

Manage all your GitHub Actions workflows across multiple projects.
Synchronize to and from all your projects.
Apply changes to similar workflows at once across all your projects.

## Setup

1. Create a repository from this template, leave "Include all branches" unchecked.
    - You can make this repository public, or keep it private.
2. Create a PAT and store it as a secret.
    1. Visit <https://github.com/settings/tokens>
    2. Click "Generate new token" with scopes:
        - **repo** (needed because this is a private repository)
        - **workflow** (needed to change workflows in other repos, implies **repo**)
    3. Copy generated token
    4. Store it as a secret named `TOKEN_KEYS`

## Design

Branches in this *central repository* correspond to projects (*remote repositories*) on GitHub.
Each branch here contains the history of `.github/workflows` in the corresponding remote repository.
Existing projects can be imported with their history.
Projects that don't have GitHub Actions yet can inherit from an existing project by creating a new branch from an existing branch in the central repository.

From then on, pushes to the central repository apply the new commits to the remote repository, with a technique similar to `git subtree`.
Backwards synchronization happens on schedule and is a variant of the initial import.
Whenever the code in the central repository is identical to the remote code, a full import of the remote history is carried out.
If the remote code is different (e.g. if you changed the actions directly in the remote repository), an attempt is made to isolate the commits from the remote history and to apply them here.

Branches that start with `main` are special, so is the `gh-pages` branch.
Also, branches that don't have a slash in their name are not synchronized with repositories.

### Is it safe?

The central repository never performs force-push or delete actions to remote repositories.
Workflows in remote repositories will contain a history of all changes that came from the central repository.

### Example

> Example: I maintain [r-dbi/DBI](https://github.com/r-dbi/DBI), [r-dbi/RKazam](https://github.com/r-dbi/RKazam) and [r-lib/rprojroot](https://github.com/r-lib/rprojroot), among other projects.
> The central repository has branches:
>
> - [r-dbi/DBI](https://github.com/krlmlr/actions-sync/tree/r-dbi/DBI)
> - [r-dbi/RKazam](https://github.com/krlmlr/actions-sync/tree/r-dbi/RKazam)
> - [r-lib/rprojroot](https://github.com/krlmlr/actions-sync/tree/r-lib/rprojroot)
> - ...
>
> The top level of these branches contain the `.yaml` files from the `.github/workflows` directory in the remote repositories.
> It also contains its own `.github` directory that powers the synchronization but is not copied to the remote repository.
>
> An overview page over all workflows in remote repositories, updated daily, is deployed to <https://krlmlr.github.io/actions-sync/>.

## Basic workflow

1. Import a project, one of:
    1. Trigger the ["Import/refresh remote repositories" action](https://github.com/krlmlr/actions-sync/actions?query=workflow%3A%22Import%2Frefresh+remote+repositories%22): click "Run workflow", enter the owner/repo of the repository you want to import
    1. `bin/import owner/repo`
1. Copy the setup for an existing *base* project to a new project, one of:
    1. Trigger the ["Import/refresh remote repositories" action](https://github.com/krlmlr/actions-sync/actions?query=workflow%3A%22Import%2Frefresh+remote+repositories%22): click "Run workflow", enter the owner/repo of the repository you want to import and the name of the base owner/repo of the boilerplate repository
    1. `bin/import_base owner/repo base-owner/base-repo`
1. Synchronization from this repository to the remote repositories:
    - automatically via GitHub Actions, on push
1. Synchronization from the remote repositories to this repository:
    - automatically via GitHub Actions, on schedule or triggered

There are also manual ways to synchronize but this will bork your work trees.
Use with care!

## Editing workflows locally

Tested on Ubuntu.
Requires GNU `parallel`.

1. Extract all branches as worktrees locally, to the `wt/` directory:

    ```sh
    bin/add_worktrees
    ```

1. Check history by date in all worktrees, to remind you which actions have been updated recently in which remote repository:

    ```sh
    git log --all --graph --date-order
    ```

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

    - Show diff for all worktrees:

        ```sh
        bin/wt_git diff
        ```

    - Commit all worktrees:

        ```sh
        bin/wt_git commit -m "My commit message"
        ```

    - Alternatively, if you want to cherry-pick a commit and apply to all worktrees

        ```sh
        bin/wt_git cherry-pick commitSha
        ```

1. Push all worktrees:

    ```sh
    git push --all
    ```

    - You can also add `-n` to verify what happens

    ```sh
    git push --all -n
    ```

    - After push to this repository, the contents are synchronized with the remote repository by GitHub Actions

1. Clean up all worktrees

    ```sh
    bin/remove_worktrees
    ```

## Maintaining similar yet different workflows across projects

For R projects, workflows may differ across projects:

- Success conditions for CI may be loosened for some projects or on some R versions
- Additional software may need to be installed for some projects
- The test matrix may contain additional entries for some projects

This will be similar also for other environments.

To make this maintainable in the longer term, I use a `base` branch that contains the common parts.
Extension points are placed in the `.yaml` files surrounded by "# Begin custom:" and "# End custom:" comments.
If the base workflow changes, most of the time the change can be cherry-picked into the project branches without conflicts: the comments serve as anchors that isolate the custom from the common parts.

- Apply the last commit of the `base` branch to all other branches:

    ```sh
    bin/wt_git cherry-pick base
    ```

- Apply the last three commits of the `base` branch to all other branches:

    ```sh
    bin/wt_git cherry-pick base~3..base
    ```

If a workflow in a remote repository changes common parts, they are brought back into the `base` branch.

```sh
cd wt/base
git checkout -f owner/repo -- .
# Keep only desired changes
git add .
git commit -f
cd ../..
```

For a "tabula rasa" style setup, we can also overwrite worktrees with the contents of a branch.

- Copy over `workflow.yaml` from the `base` branch to all other branches:

    ```sh
    bin/wt_git checkout -f base -- workflow.yaml
    ```

- Copy over the contents of the `base` branch to all other branches:

    ```sh
    bin/wt_copy_to base-branch
    ```

## Troubleshooting

If the synchronization breaks for one or multiple repositories, remove the corresponding repository branch and re-add.

## Hacking

Code is in `lib/lib.sh`.
Public functions don't start with an underscore and have a comment on the line of the function definition.
This is used for creating the command scripts and for the usage.

### Update command scripts

```sh
./run.sh _make_commands
```
