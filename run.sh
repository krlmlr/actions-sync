#!/bin/bash

add_worktrees() {
	git branch -r | egrep -v 'main' | sed 's#  origin/##' | xargs -r -n 1 ./run.sh _add_worktree
}

_add_worktree() {
  git worktree add wt/"$1" "$1"
}

pull() {
  echo "$1"
  git -C "$1" pull --ff-only
}

if [ "$1" = "" ]; then
  echo "Usage: $0 command ..."
  echo "with command one of:"
  sed -r -n '/^([a-z].*)[(][)] [{]$/ { s//- \1/; p }' $0
  exit 1
fi

"$@"
