RUN_SUBDIRS := $(notdir $(patsubst %/.,%,$(wildcard run/*/.)))
RUN_SCRIPTS := $(filter-out $(RUN_SUBDIRS),$(notdir $(wildcard run/*)))

COMMAND_FILES := $(foreach script,$(RUN_SCRIPTS),$(wildcard $(COMMONS_DIR)/make/commands/$(script).mk))
COMMAND_NAMES := $(sort $(notdir $(basename $(COMMAND_FILES))))
GENERIC_RUN_SCRIPTS := $(sort $(filter-out $(COMMAND_NAMES),$(RUN_SCRIPTS)))

_EXTRA_GOALS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ARGS := $(_EXTRA_GOALS)
$(foreach g,$(_EXTRA_GOALS),$(eval .PHONY: $(g))$(eval $(g):;@true))

-include $(COMMAND_FILES)

define GENERIC_RUN_RULE
.PHONY: run.$(1)
run.$(1):
	@$(COMMONS_DIR)/shell/helpers/devmode/runner.sh $(DEV_MODE) run/$(1) $(ARGS)
endef

$(foreach script,$(GENERIC_RUN_SCRIPTS),$(eval $(call GENERIC_RUN_RULE,$(script))))
