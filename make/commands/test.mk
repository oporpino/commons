.PHONY: run.test

run.test: ### Run test suite (use path=<path> to filter)
	@$(COMMONS_DIR)/shell/helpers/devmode/runner.sh $(DEV_MODE) run/test $(path)
