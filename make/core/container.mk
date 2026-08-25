ifeq ($(DEV_MODE),container)

DEV_CONTAINER_SERVICES := $(shell sh $(COMMONS_DIR)/shell/tasks/dev-mode/services.sh)

define DEV_CONTAINER_SHELL_RULE
.PHONY: shell.$(1)
shell.$(1):
	@$(COMMONS_DIR)/shell/tasks/dev-mode/shell.sh $(1)
endef

$(foreach service,$(DEV_CONTAINER_SERVICES),$(eval $(call DEV_CONTAINER_SHELL_RULE,$(service))))

.PHONY: shell
### Shell into the app container (or make shell.<service>)
shell: shell.app

endif
