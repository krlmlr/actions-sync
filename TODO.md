# TODO

- Add code to prune branches in fork
- Add workflow to create commands
- Add code to sync/copy base to other branches

## Later

- Remove hard-coded github.com

## Caveat

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
