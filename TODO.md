# TODO

- Fix failing workflows
- Harmonize
    - rcc: r-prof/winch
    - Begin custom:
    - Show testthat output -> show test output
    - Decide on R 3.2
- Add code to prune branches in fork
- Add workflow to create commands
- Add code to sync/copy base to other branches

## Later

- Remove hard-coded github.com

## Caveat

- Sync from remote repos overwrites history due to change in committer date. Can we cherry-pick with the original committer date? Do we need a low-level Git command?
    - Problem: commit from internal `.github/workflows`:

        ```text
        * commit 5a4351d22b75280073c26cbf58bd145a8b49600f (origin/r-prof/winch)
        | Author:     Kirill Müller <krlmlr@mailbox.org>
        | AuthorDate: Tue Dec 8 07:37:07 2020 +0000
        | Commit:     Kirill Müller <krlmlr@mailbox.org>
        | CommitDate: Tue Dec 8 07:37:07 2020 +0000
        |
        |     Update push action
        |
        | 35    0       .github/workflows/push-on-change.yaml
        |
        | * commit 56ddb0b20f1bdf08681476e25c36c7be1b6096ff (r-prof/winch)
        |/  Author:     Kirill Müller <krlmlr@mailbox.org>
        |   AuthorDate: Tue Dec 8 00:44:40 2020 +0000
        |   Commit:     Kirill Müller <krlmlr@mailbox.org>
        |   CommitDate: Tue Dec 8 00:44:40 2020 +0000
        |
        |       Update push action
        |
        |   35  0       .github/workflows/push-on-change.yaml
        |
        ```

    - Can be solved only by keeping `.github/workflows/.github` directory, or by synchronization on refresh/reimport, e.g. "FIXME: If branch exists, perform double rebase; fall back to force if fails"

- Merges in local history can't be easily recreated in the remote repos

- Push to `templates/` then unrelated push doesn't trigger workflow?

## Done

- How to remove?
    - Remove branch, no foreign workflows
- Switch to scheduled sync back
    - Add local sync back action to every branch: doesn't work, scheduled works only for main branch
- Think about sync back on remote change
    - No
        - Implement merge back
            - With import, refresh=FALSE
            - Test with RKazam
        - How to resend secret to remote repository -- manual workflow run?
        - Trigger resend of secret when key is regenerated
