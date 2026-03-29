.SILENT:
-include .env
export

APP_NAME ?= $(notdir $(CURDIR))

.DEFAULT_GOAL := help

include .commons/make/core/git.mk
include .commons/make/core/ai.mk
include .commons/make/core/release.mk
