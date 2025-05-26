.PHONY: git.add git.commit git.pull git.update git.status help

# Detect if we're running from inside .commons or from root
IS_COMMONS := $(shell basename $$(pwd) | grep -q "^.commons$$" && echo "true" || echo "false")

# Add files to git in main project and submodules
git.add:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/add
else
	@bash .commons/scripts/make/git/add
endif

# Commit changes in main project and submodules
git.commit:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/commit
else
	@bash .commons/scripts/make/git/commit
endif

# Pull changes in main project and submodules
git.pull:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/pull
else
	@bash .commons/scripts/make/git/pull
endif

# Update all modules
git.update:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/update
else
	@bash .commons/scripts/make/git/update
endif

# Show status of main project and submodules
git.status:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/status
else
	@bash .commons/scripts/make/git/status
endif

# Show help
help:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/help
else
	@bash .commons/scripts/make/help
endif
