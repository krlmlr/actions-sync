set -e

_make_commands() {
  rm -rf bin
  mkdir bin

  cat > run.sh <<"EOF"
#!/bin/bash

. lib/lib.sh

if [ "$1" = "" ]; then
  echo "Usage: $0 command ..."
  echo
  echo "with command one of:"
  echo
  sed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//- \1: \2/; p }' lib/lib.sh
  exit 1
fi

echo "> $1"

"$@"
EOF
  chmod +x run.sh

  sed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//\1 "\2"/; p }' lib/lib.sh | parallel ./run.sh _make_command
}

_make_command() {
  _make_command_uq $@
}

_make_command_uq() {
  command=$1
  shift
  comment="$@"

  echo ${command}

  cat > bin/${command} <<EOF
#!/bin/bash

. lib/lib.sh

# ${comment}

${command} "\$@"
EOF

  chmod +x bin/${command}
}

add_worktrees() { # Add all branches representing workflows in foreign repositories as worktrees in the wt/ directory
  git branch -r | egrep -v 'main' | sed 's#  origin/##' | xargs -r -n 1 ./run.sh _add_worktree
}

_add_worktree() {
  repo="$1"
  shift

  if [ -d wt/"$repo" ]; then
    echo "Worktree wt/$repo exists."
    return
  fi

  if [ "$1" = "" ]; then
    branch="$repo"
  else
    branch="$1"
    shift
  fi

  git worktree add wt/"$repo" "$branch"
}

wt_run() { # Run command in all worktrees, use '{}' as placeholder for worktree directory
  _provide_wt
  find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' ./run.sh "$@"
}

_provide_wt() {
  if ! [ -d wt ]; then
    add_worktrees
  fi
}

wt_git() { # Run git command in all worktrees
  wt_run _wtdir_git '{}' "$@"
}

_wtdir_git() {
  git_dir="$1"
  shift

  echo "$git_dir"
  git -C "$git_dir" "$@"
}

wt_pull() { # Run git pull --ff-only for all worktrees
  wt_git pull --ff-only
}

copy_templates() { # Copy workflow templates into foreign repository
  rm -rf wt/*/*/.github
  wt_run _copy_template
}

_copy_template() {
  repo="$1"
  shift

  echo "$repo"
  cp -r template/{*,.??*} "$repo"
  git -C "$repo" add .
  if ! git -C "$repo" diff-index --quiet HEAD; then
    git -C "$repo" commit -m 'Update push action'
    git -C "$repo" push "$@"
  else
    echo "No changes"
  fi
}

remove_worktrees() { # Remove wt/ directory and all local branches. Potentially destructive, check output!
  git worktree list | egrep -v '[[]main[]]' | cut -d " " -f 1 | xargs -r -n 1 git worktree remove
  if [ -d $(echo wt/* | cut -d " " -f 1) ]; then
    rmdir wt/*
  fi
  if [ -d wt ]; then
    rmdir wt
  fi
  git branch | egrep -v 'main' | xargs -r git branch -d || git branch | egrep -v 'main' | xargs -r git branch -D
}

wt_merge_with() { # Merge a branch into all worktrees, don't commit. Pass local branch as argument
  base="$1"
  shift
  wt_git merge "$1" --no-commit
}

wt_git_dm() { # Run git dm on all worktrees, requires krlmlr/scriptlets
  wt_git dm
}

wt_finish_merge() { # Finish merging, push
  wt_run _wtdir_finish_merge
}

_wtdir_finish_merge() {
  git_dir="$1"
  shift
  if git -C "$git_dir" diff-index --quiet HEAD; then
    git -C "$git_dir" commit --no-edit
    git -C "$git_dir" push
  fi
}

refresh_all() { # Refresh all repositories
  git branch -r | egrep -v 'main' | sed 's#  origin/##' | grep '/' | parallel ./run.sh _force_import
}

_force_import() {
  import "$1" --force
}

import() { # Import a new repository, pass slug as argument
  new_repo="$1"

  if [ "$new_repo" = "" ]; then
    echo "Usage: $0 owner/repo"
    exit 1
  fi

  shift

  mkdir -p import/${new_repo}
  git clone https://${TOKEN_KEYS}@github.com/${new_repo} import/${new_repo}

  cd import/${new_repo}

  if [ $(git log --oneline -- .github/workflows | head -n 1 | wc -l) = 0 ]; then
    echo "NYI: importing empty branch"
    # https://stackoverflow.com/a/53919745/946850
    false
  else
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --subdirectory-filter .github/workflows --prune-empty
    import_branch=$(git branch | cut -d " " -f 2)

    cd ../../..

    git remote add import/${new_repo} import/${new_repo}
    git fetch import/${new_repo}
    git branch --no-track ${new_repo} import/${new_repo}/${import_branch} -f
    git remote remove import/${new_repo}

    _add_worktree "$new_repo"
  fi

  rm -rf import/${new_repo}
  _copy_template wt/${new_repo} -u origin HEAD "$@"
}

merge_into_remote() { # Merge our workflow into the remote repository. Makes worktree unusable. Takes the slug as argument
  repo="$1"
  if [ "$repo" = "" ]; then
    echo "Usage: $0 owner/repo"
    exit 1
  fi

  shift

  _provide_wt

  cd wt/${repo}
  # --env-filter: https://stackoverflow.com/a/38586928/946850
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --env-filter 'export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"' --tree-filter 'rm -rf .github/ && mkdir -p .github/workflows/ && mv * .github/workflows/ || true' --prune-empty -f
  cd ../../..

  git clone https://${TOKEN_KEYS}@github.com/${repo} remote
  cd remote

  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --env-filter 'export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"' --subdirectory-filter .github/workflows --prune-empty -f
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --env-filter 'export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"' --tree-filter 'rm -rf .github/ && mkdir -p .github/workflows/ && mv * .github/workflows/ || true' --prune-empty -f

  import_branch=$(git branch | cut -d " " -f 2)
  git branch subtree
  git reset --hard origin/${import_branch}

  git remote add actions ..
  git fetch actions

  if [ $(git log --pretty=oneline actions/${repo} ^subtree | head -n 1 | wc -l) -gt 0 ]; then
    git cherry-pick actions/${repo} ^subtree --allow-empty --first-parent -m 1 --no-edit
    git push
  fi
  cd ..
  rm -rf remote
}
