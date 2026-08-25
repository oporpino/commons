# =============================================================================
# SETUP - Project-Level Configuration
# =============================================================================
# Configures this specific project on the machine.
# Safe to run on a freshly cloned project or to re-run on an existing one.

.PHONY: setup

### Setup - Configure project (.claude, .env, stack)
setup:
	@STACK="$(STACK)" bash $(COMMONS_DIR)/shell/tasks/setup/project.sh $(SETUP_ARGS)
