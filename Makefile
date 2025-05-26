.PHONY: git.add

# Detect if we're running from inside .commons or from root
IS_COMMONS := $(shell basename $$(pwd) | grep -q "^.commons$$" && echo "true" || echo "false")

# Add files to git in main project and submodules
git.add:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/add
else
	@bash .commons/scripts/make/git/add
endif
