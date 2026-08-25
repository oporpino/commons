
# aliases
release: _release.create

# release management
_release.create:
	@$(COMMONS_DIR)/shell/tasks/release/create.sh

release.patch:
	@$(COMMONS_DIR)/shell/tasks/release/create.sh --patch --auto-approve
