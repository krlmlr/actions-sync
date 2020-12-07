all:
	false

wt:
	./run.sh add_worktrees

pull:
	find wt/*/* -maxdepth 0 -type d | parallel -q ./run.sh pull

copy_templates: wt
	./run.sh copy_templates

.wt:
	git worktree list | egrep -v '[[]main[]]' | cut -d " " -f 1 | xargs -r -n 1 git worktree remove
	if [ -d $(echo wt/* | head -n 1) ]; then rmdir wt/*; fi
	if [ -d wt ]; then rmdir wt; fi
	git branch | egrep -v 'main' | xargs -r git branch -d || git branch | egrep -v 'main' | xargs -r git branch -D

# Requires krlmlr/scriptlets for git dm
sync-with-%: wt
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' sh -c "echo '* {}' && git -C '{}' merge $(subst sync-with-,,$@) --no-commit"

diffuse: wt
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' git -C '{}' dm

finish-sync:
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' sh -c "git -C '{}' diff-index --quiet HEAD || git -C '{}' commit --no-edit"
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' git -C '{}' push
