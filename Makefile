all:
	false

wt:
	git branch -r | egrep -v 'main' | sed 's#  origin/##' | xargs -r -n 1 -I '{}' git worktree add wt/'{}' '{}'

copy-templates: wt
	rm -rf wt/*/*/.github
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' cp -r template '{}'/.github
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' git -C '{}' add .
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' sh -c "git -C '{}' diff-index --quiet HEAD || git -C '{}' commit -m 'Update push action'"
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' git -C '{}' push

.wt:
	git worktree list | egrep -v '[[]main[]]' | cut -d " " -f 1 | xargs -r -n 1 git worktree remove
	if [ -d wt/* ]; then rmdir wt/*; fi
	if [ -d wt ]; then rmdir wt; fi
