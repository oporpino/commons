ifeq ($(strip $(COMMONS_DIR)),)
$(error COMMONS_DIR is not set. It is exported by ~/.zshrc during machine setup. Reload your shell with: exec zsh (or: source ~/.zshrc). New machine? run the WeHive setup first)
endif

.SILENT:
-include .env

APP_NAME ?= $(notdir $(CURDIR))
PROJECT_DIR ?= $(CURDIR)

export APP_NAME
export PROJECT_DIR

.DEFAULT_GOAL := help

include $(COMMONS_DIR)/make/core/commands.mk
include $(COMMONS_DIR)/make/core/help.mk
include $(COMMONS_DIR)/make/core/mobile/release.mk
include $(COMMONS_DIR)/make/core/commons.mk
include $(COMMONS_DIR)/make/core/setup.mk
