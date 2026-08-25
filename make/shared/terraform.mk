# =============================================================================
# TERRAFORM MAKEFILE (Reusable)
# =============================================================================
# Set SKIP_TERRAFORM_MK=1 before including this file to skip all target
# definitions (useful when a project defines its own terraform.* targets).
ifdef SKIP_TERRAFORM_MK
else

# Override terraform directory:
#   TERRAFORM_DIR ?= .infra/terraform    # in your Makefile, before the include
TERRAFORM_DIR ?= .infra/terraform

.PHONY: terraform.init terraform.plan terraform.apply terraform.output terraform.destroy
.PHONY: terraform.staging.init terraform.staging.plan terraform.staging.apply terraform.staging.output terraform.staging.destroy
.PHONY: terraform.production.init terraform.production.plan terraform.production.apply terraform.production.output terraform.production.destroy

# =============================================================================
# GENERIC TERRAFORM COMMANDS (prompts for workspace)
# =============================================================================

### Terraform - Initialize (asks for workspace)
terraform.init:
	@echo "Select workspace:"; \
	echo "  1) staging"; \
	echo "  2) production"; \
	read -p "Choice [1]: " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then $(MAKE) terraform.staging.init; \
	elif [ "$$choice" = "2" ]; then $(MAKE) terraform.production.init; \
	else echo "Invalid choice"; exit 1; fi

### Terraform - Plan changes (asks for workspace)
terraform.plan:
	@echo "Select workspace:"; \
	echo "  1) staging"; \
	echo "  2) production"; \
	read -p "Choice [1]: " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then $(MAKE) terraform.staging.plan; \
	elif [ "$$choice" = "2" ]; then $(MAKE) terraform.production.plan; \
	else echo "Invalid choice"; exit 1; fi

### Terraform - Apply changes (asks for workspace)
terraform.apply:
	@echo "Select workspace:"; \
	echo "  1) staging"; \
	echo "  2) production"; \
	read -p "Choice [1]: " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then $(MAKE) terraform.staging.apply; \
	elif [ "$$choice" = "2" ]; then $(MAKE) terraform.production.apply; \
	else echo "Invalid choice"; exit 1; fi

### Terraform - Show outputs (asks for workspace)
terraform.output:
	@echo "Select workspace:"; \
	echo "  1) staging"; \
	echo "  2) production"; \
	read -p "Choice [1]: " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then $(MAKE) terraform.staging.output; \
	elif [ "$$choice" = "2" ]; then $(MAKE) terraform.production.output; \
	else echo "Invalid choice"; exit 1; fi

### Terraform - Destroy infrastructure (asks for workspace)
terraform.destroy:
	@echo "Select workspace:"; \
	echo "  1) staging"; \
	echo "  2) production"; \
	read -p "Choice [1]: " choice; \
	choice=$${choice:-1}; \
	if [ "$$choice" = "1" ]; then $(MAKE) terraform.staging.destroy; \
	elif [ "$$choice" = "2" ]; then $(MAKE) terraform.production.destroy; \
	else echo "Invalid choice"; exit 1; fi

# =============================================================================
# WORKSPACE-SPECIFIC TERRAFORM COMMANDS
# =============================================================================

### Terraform Staging - Initialize
terraform.staging.init:
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).staging -- terraform init && \
	ward exec $(WARD_PATH).staging -- terraform workspace select staging 2>/dev/null \
		|| ward exec $(WARD_PATH).staging -- terraform workspace new staging

### Terraform Staging - Plan changes
terraform.staging.plan:
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).staging -- terraform plan

### Terraform Staging - Apply changes
terraform.staging.apply:
	@if [ -f run/terraform/hooks/pre-apply.sh ]; then bash run/terraform/hooks/pre-apply.sh staging; fi
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).staging -- terraform apply -auto-approve
	@if [ -f run/terraform/hooks/post-apply.sh ]; then bash run/terraform/hooks/post-apply.sh staging; fi

### Terraform Staging - Show outputs
terraform.staging.output:
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).staging -- terraform output

### Terraform Staging - Destroy infrastructure
terraform.staging.destroy:
	@if [ -f run/terraform/hooks/pre-destroy.sh ]; then bash run/terraform/hooks/pre-destroy.sh staging; fi
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).staging -- terraform destroy -auto-approve
	@if [ -f run/terraform/hooks/post-destroy.sh ]; then bash run/terraform/hooks/post-destroy.sh staging; fi

### Terraform Production - Initialize
terraform.production.init:
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).production -- terraform init && \
	ward exec $(WARD_PATH).production -- terraform workspace select production 2>/dev/null \
		|| ward exec $(WARD_PATH).production -- terraform workspace new production

### Terraform Production - Plan changes
terraform.production.plan:
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).production -- terraform plan

### Terraform Production - Apply changes
terraform.production.apply:
	@if [ -f run/terraform/hooks/pre-apply.sh ]; then bash run/terraform/hooks/pre-apply.sh production; fi
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).production -- terraform apply -auto-approve
	@if [ -f run/terraform/hooks/post-apply.sh ]; then bash run/terraform/hooks/post-apply.sh production; fi

### Terraform Production - Show outputs
terraform.production.output:
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).production -- terraform output

### Terraform Production - Destroy infrastructure
terraform.production.destroy:
	@if [ -f run/terraform/hooks/pre-destroy.sh ]; then bash run/terraform/hooks/pre-destroy.sh production; fi
	@cd $(TERRAFORM_DIR) && \
	ward exec $(WARD_PATH).production -- terraform destroy -auto-approve
	@if [ -f run/terraform/hooks/post-destroy.sh ]; then bash run/terraform/hooks/post-destroy.sh production; fi

endif # SKIP_TERRAFORM_MK
