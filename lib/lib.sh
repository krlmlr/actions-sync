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
  gsed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//- \1: \2/; p }' lib/lib.sh
  return 1
fi

echo "> $1"

"$@"
EOF
  chmod +x run.sh

  gsed -r -n '/^([a-z].*)[(][)] [{] +# (.*)$/ { s//\1 "\2"/; p }' lib/lib.sh | parallel ./run.sh _make_command
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
  git branch -r | egrep -v 'main|/gh-pages$' | sed 's#  origin/##' | xargs -r -n 1 ./run.sh _add_worktree
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
  find wt/base wt/*/* -maxdepth 0 -type d | grep -v '/base/' | parallel -q -I '{}' ./run.sh "$@"
}

wt_run_serial() { # Run command in all worktrees, use '{}' as placeholder for worktree directory
  _provide_wt
  ${SHELL} -ic "$( find wt/*/* -maxdepth 0 -type d | parallel echo ./run.sh "$@" "< /dev/tty ;" )"
}

_provide_wt() {
  if ! [ -d wt ]; then
    add_worktrees
  fi
}

wt_git() { # Run git command in all worktrees
  wt_run _wtdir_git '{}' "$@"
}

wt_git_serial() { # Run git command in all worktrees, with terminal support
  wt_run_serial _wtdir_git '{}' "$@"
}

_wtdir_git() {
  git_dir="$1"
  shift

  git -C "$git_dir" "$@"
}

wt_pull() { # Run git pull --ff-only for all worktrees
  wt_git pull --ff-only
}

copy_templates() { # Copy workflow templates into foreign repositories
  wt_run _copy_template '{}'
}

_copy_template() {
  repo="$1"
  shift

  echo "$repo"
  rm -rf "$repo"/.github
  cp -r template/.github "$repo"
  git -C "$repo" add .
  if ! git -C "$repo" diff-index --quiet HEAD; then
    git -C "$repo" commit -m 'Update push action'
  else
    echo "No changes"
  fi
  # Always push, could be a copy from a base branch that has all push actions
  git -C "$repo" push "$@"
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

wt_copy_to() { # Copy a branch into all worktrees, don't commit. Pass local branch as argument
  base="$1"
  shift
  wt_git checkout -f "$base" -- .
}

refresh_all() { # Refresh all repositories
  git branch -r | egrep -v 'main' | sed 's#  origin/##' | grep '/'
  git branch -r | egrep -v 'main' | sed 's#  origin/##' | grep '/' | parallel -j 1 --joblog refresh_all.log ./run.sh _force_import
}

_force_import() {
  import "$1" --force
}

import() { # Import a new repository, pass slug as argument
  new_repo="$1"
  if [ "$new_repo" = "" ]; then
    echo "Usage: $0 owner/repo"
    return 1
  fi

  shift

  import_base "$new_repo" "" "$@"
}

import_base() { # Import a new repository with fallback to a base branch, pass slug and base branch as argument
  new_repo="$1"

  if [ "$new_repo" = "" ]; then
    echo "Usage: $0 owner/repo base-owner/base-repo"
    return 1
  fi

  shift

  base="$1"

  shift

  _provide_wt

  mkdir -p import/${new_repo}
  git clone https://${TOKEN_KEYS}@github.com/${new_repo} import/${new_repo}

  cd import/${new_repo}

  if [ $(git log --oneline -- .github/workflows | head -n 1 | wc -l) = 0 ]; then
    if [ -z "$base" ]; then
      echo "Remote repository ${new_repo} has no workflows, need base branch."
      return 1
    fi

    cd ../../..

    git branch --no-track ${new_repo} ${base} -f
  else
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --subdirectory-filter .github/workflows --prune-empty 2>&1 | sed -r 's/\r?Rewrite [^)]+[)][^(]*[(][^)]*[)]//g'
    import_branch=$(git branch | cut -d " " -f 2)

    cd ../../..

    git remote add import/${new_repo} import/${new_repo}
    git fetch import/${new_repo}

    if [ -n "$(git branch --list ${new_repo})" ]; then
      _add_worktree "$new_repo"

      echo "Checking if remote different"
      if [ $(git -C wt/${new_repo} diff import/${new_repo}/${import_branch} --numstat | egrep -v "[[:space:]][.]github/" | wc -l) = 0 ]; then
        echo "Remote identical"
        if [ $(git -C wt/${new_repo} diff import/${new_repo}/${import_branch} HEAD^ --numstat | wc -l) -gt 0 ]; then
          echo "Resetting history to remote"
          git worktree remove -f "$new_repo"
          git branch --no-track ${new_repo} import/${new_repo}/${import_branch} -f
        else
          echo "Local branch is remote plus our action, nothing to do"
        fi
      elif ! ( cd wt/${new_repo} && git rebase -q import/${new_repo}/${import_branch} --rebase-merges && git rebase -q --rebase-merges); then
        echo "Rebase failed, reconcile differences manually"
        return 1
      fi
    else
      # Branch doesn't exist: create
      git branch --no-track ${new_repo} import/${new_repo}/${import_branch}
    fi

    git remote remove import/${new_repo}
  fi

  rm -rf import/${new_repo}

  _add_worktree "$new_repo"

  _copy_template wt/${new_repo} -u origin HEAD "$@"
}

merge_into_remote() { # Merge our workflow into the remote repository. Makes worktree unusable. Takes the slug as argument
  repo="$1"
  if [ "$repo" = "" ]; then
    echo "Usage: $0 owner/repo"
    return 1
  fi

  shift

  _provide_wt

  cd wt/${repo}
  # --env-filter: https://stackoverflow.com/a/38586928/946850
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --env-filter 'export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"' --tree-filter 'rm -rf .github/ && mkdir -p .github/workflows/ && mv * .github/workflows/ || true' --prune-empty -f 2>&1 | sed -r 's/\r?Rewrite [^)]+[)][^(]*[(][^)]*[)]//g'
  cd ../../..

  git clone https://${TOKEN_KEYS}@github.com/${repo} remote
  cd remote

  git remote add actions ..
  git fetch actions

  if [ $(git log --oneline -- .github/workflows | head -n 1 | wc -l) = 0 ]; then
    echo "Green field"
    # Green field, squash-merge all commits
    git merge actions/${repo} --allow-unrelated --squash --ff
    git commit --no-edit
    git push
  else
    echo "Integrate"
    # At least one remote commit
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --subdirectory-filter .github/workflows --prune-empty -f 2>&1 | sed -r 's/\r?Rewrite [^)]+[)][^(]*[(][^)]*[)]//g'
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --tree-filter 'rm -rf .github/ && mkdir -p .github/workflows/ && mv * .github/workflows/ || true' --prune-empty -f 2>&1 | sed -r 's/\r?Rewrite [^)]+[)][^(]*[(][^)]*[)]//g'

    import_branch=$(git branch | cut -d " " -f 2)
    git branch subtree
    git reset --hard origin/${import_branch}

    # Rebase actions-sync onto subtree
    # to ignore differences in committer date
    # and out-of-order commits
    git branch actions-sync actions/${repo}
    git checkout actions-sync

    # Without --rebase-merges, pillar and dm fail
    # With --rebase-merges, sometimes empty commits remain
    # The combination is even worse.
    if ! ( git rebase -q --rebase-merges subtree ); then
      echo "Warning: Rebase failed"
      git rebase --abort
    fi

    git checkout ${import_branch}

    # Cherry-pick differences onto target branch
    # FIXME: Will a rebase work here too?
    if [ $(git log --pretty=oneline actions-sync ^subtree | head -n 1 | wc -l) -gt 0 ]; then
      if ! git cherry-pick actions-sync ^subtree --allow-empty --first-parent -m 1 --no-edit; then
        git cherry-pick --abort
        git diff actions-sync ^subtree | patch -p1
        if [ $(git status --porcelain | wc -l) -gt 0 ]; then
          git add .
          git commit -m "ci: Import from actions-sync, check carefully"
        fi
      fi
      git push
    else
      echo "Nothing to cherry-pick"
    fi
  fi
  cd ..
  rm -rf remote
}
