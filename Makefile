all:
	false

wt:
	git branch -r | egrep -v 'main' | sed 's#  origin/##' | xargs -r -n 1 -I '{}' git worktree add wt/'{}' '{}'

.wt:
	git worktree list | egrep -v '[[]main[]]' | cut -d " " -f 1 | xargs -r -n 1 git worktree remove
	if [ -d wt/* ]; then rmdir wt/*; fi
	if [ -d wt ]; then rmdir wt; fi

