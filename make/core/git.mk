.PHONY: git.add git.commit git.pull git.update git.status

git.add: ## Add files to git in main project and submodules
	@bash .commons/scripts/make/core/git/add.sh

git.commit: ## Commit changes in main project and submodules
	@bash .commons/scripts/make/core/git/commit.sh

git.pull: ## Pull changes in main project and submodules
	@bash .commons/scripts/make/core/git/pull.sh

git.update: ## Update all modules
	@bash .commons/scripts/make/core/git/update.sh

git.status: ## Show status of main project and submodules
	@bash .commons/scripts/make/core/git/status.sh
