.PHONY: git.add

# Detect if we're running from inside .commons or from root
IS_COMMONS := $(shell basename $$(pwd) | grep -q "^.commons$$" && echo "true" || echo "false")

# Add files to git in main project and submodules
git.add:
ifeq ($(IS_COMMONS),true)
	@scripts/make/git/add
else
	@.commons/scripts/make/git/add
endif
