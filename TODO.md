# TODO

- Switch to scheduled sync back
    - Cleanup secrets from remote repositories
    - Remove code that generates secret
    - Remove deploy key
- Think about sync back on remote change
- Add code to prune branches in fork
- Import other projects:
    - MultiLevelIPF (no GHA yet)
    - r-prof/profile
- Implement merge back
    - With import, refresh=FALSE
    - Test with RKazam
- How to resend secret to remote repository -- manual workflow run?
- Trigger resend of secret when key is regenerated
- Remove hard-coded github.com
- How to remove?
    - Remove branch, foreign workflow won't notice
