include .commons/make/core/main.mk

.PHONY: build

build: ## Build release binary
	@cargo build --release
