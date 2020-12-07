# TODO

- Import other projects:
    - MultiLevelIPF (no GHA yet)
    - r-prof/profile
- Add code to prune branches in fork
- Implement merge back
    - With import, refresh=FALSE
    - Test with RKazam
- How to resend secret to remote repository -- manual workflow run?
- Trigger resend of secret when key is regenerated
- Remove hard-coded github.com
- How to remove?
    - Remove branch, foreign workflow won't notice

## Done

- Switch to scheduled sync back
    - Add local sync back action to every branch: doesn't work, scheduled works only for main branch
- Think about sync back on remote change
    - No
