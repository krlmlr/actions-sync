all:
	false

wt:
	./run.sh add_worktrees

pull:
	find wt/*/* -maxdepth 0 -type d | parallel -q ./run.sh pull

copy_templates: wt
	./run.sh copy_templates

.wt:
	./run.sh remove_worktrees

# Requires krlmlr/scriptlets for git dm
sync-with-%: wt
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' sh -c "echo '* {}' && git -C '{}' merge $(subst sync-with-,,$@) --no-commit"

diffuse: wt
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' git -C '{}' dm

finish-sync:
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' sh -c "git -C '{}' diff-index --quiet HEAD || git -C '{}' commit --no-edit"
	find wt/*/* -maxdepth 0 -type d | parallel -q -I '{}' git -C '{}' push
