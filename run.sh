#!/bin/bash

add_worktrees() { # Add all branches representing workflows in foreign repositories as worktrees in the wt/ directory
	git branch -r | egrep -v 'main' | sed 's#  origin/##' | xargs -r -n 1 ./run.sh _add_worktree
}

_add_worktree() {
  git worktree add wt/"$1" "$1"
}

pull() { # Run git pull --ff-only for all worktrees
  echo "$1"
  git -C "$1" pull --ff-only
}

copy_templates() { # Copy workflow templates into foreign repository
	rm -rf wt/*/*/.github
	find wt/*/* -maxdepth 0 -type d | parallel -q ./run.sh _copy_template
}

_copy_template() {
  echo "$1"
	cp -r template "$1"
	git -C "$1" add .
	if git -C "$1" diff-index --quiet HEAD; then
    git -C "$1" commit -m 'Update push action'
	  git -C "$1" push -n
  else
    echo "No changes"
  fi
}

remove_worktrees() { # Remove wt/ directory and all local branches. Potentially destructive, check output!
	git worktree list | egrep -v '[[]main[]]' | cut -d " " -f 1 | xargs -r -n 1 git worktree remove
	if [ -d $(echo wt/* | head -n 1) ]; then
    rmdir wt/*
  fi
	if [ -d wt ]; then
    rmdir wt
  fi
	git branch | egrep -v 'main' | xargs -r git branch -d || git branch | egrep -v 'main' | xargs -r git branch -D
}

if [ "$1" = "" ]; then
  echo "Usage: $0 command ..."
  echo
  echo "with command one of:"
  echo
  sed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//- \1: \2/; p }' $0
  exit 1
fi

"$@"
