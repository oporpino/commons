ifeq ($(strip $(COMMONS_DIR)),)
$(error COMMONS_DIR is not set. It is exported by ~/.zshrc during machine setup. Reload your shell with: exec zsh (or: source ~/.zshrc). New machine? run the WeHive setup first)
endif
include $(COMMONS_DIR)/make/core/_main.mk
