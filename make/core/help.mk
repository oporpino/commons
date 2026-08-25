### Show this help message
help:
	@awk ' \
	  /^### / { desc = substr($$0, 5); next } \
	  /^[a-zA-Z][a-zA-Z0-9_.-]*:.*### / { n = index($$0, ":"); d = index($$0, "### "); printf "\033[36m%-30s\033[0m %s\n", substr($$0, 1, n-1), substr($$0, d+4); desc = ""; next } \
	  /^[a-zA-Z][a-zA-Z0-9_.-]*:/ { if (desc != "") { n = index($$0, ":"); printf "\033[36m%-30s\033[0m %s\n", substr($$0, 1, n-1), desc } desc = ""; next } \
	  { desc = "" } \
	' $(MAKEFILE_LIST) | sort
	@$(foreach s,$(GENERIC_RUN_SCRIPTS),printf "\033[36m%-30s\033[0m %s\n" "run.$(s)" "Run run/$(s) ($(DEV_MODE))";)
