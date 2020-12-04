all:
	false

worktrees:
	git branch | egrep -v 'main' | xargs -r -n 1 -I '{}' git worktree add worktrees/'{}' '{}'

remove-worktrees:
	git worktree list | egrep -v '[[]main[]]' | cut -d " " -f 1 | xargs -r -n 1 git worktree remove
	if [ -d worktrees ]; then rmdir worktrees; fi

