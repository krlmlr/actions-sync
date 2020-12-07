# TODO

- Import doesn't run push workflow
    - Add argument refresh=TRUE
    - Trigger manually if refresh=TRUE
- Implement merge back
    - With import, refresh=FALSE
    - Test with RKazam
- Add workflow to reimport all
- Add code to prune branches in fork
- Import other projects:
    - MultiLevelIPF (no GHA yet)
    - r-prof/profile
- How to resend secret to remote repository -- manual workflow run?
- Trigger resend of secret when key is regenerated
- Remove hard-coded github.com
- How to remove?
    - Remove branch, foreign workflow won't notice
