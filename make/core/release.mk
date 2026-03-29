release: ## Release a new version
	@bash .commons/scripts/make/core/release.sh

release.patch: ## Release a new patch version
	@bash .commons/scripts/make/core/release.sh --patch --auto-approve
