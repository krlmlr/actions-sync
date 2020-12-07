#!/bin/bash

. lib/lib.sh

# "Remove wt/ directory and all local branches. Potentially destructive, check output!"

remove_worktrees "$@"
