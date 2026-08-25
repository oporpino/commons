_BRANCH_NAME ?= $(or $(BRANCH_NAME),staging)
export _BRANCH_NAME

### Push current HEAD to deployment branch (force)
deploy.branch:
	@echo "\nPushing to deployment branch ${_BRANCH_NAME} ..........................................................."
	@$(COMMONS_DIR)/shell/tasks/deploy/push-to-branch.sh

heroku.deploy.staging: deploy.branch
