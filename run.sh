#!/bin/bash

add_worktree() {
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
