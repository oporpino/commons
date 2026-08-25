# =============================================================================
# INFRA MAKEFILE (Reusable)
# =============================================================================
# Combines terraform apply + k8s deploy for projects with .infra/k8s
# Included automatically via _main.mk for all projects.
#
# Requirements:
# - .infra/k8s/overlays/staging/ and .infra/k8s/overlays/production/
# - REGISTRY_BASE set in .env (e.g. 616795656532.dkr.ecr.us-east-1.amazonaws.com/wehive/)
# - kustomize and kubectl available
#
# Override defaults in the project's Makefile (single-module) or
# .module/make/main.mk (multi-module), included after this file:
#   K8S_DIR = .infra/k8s
#   IMAGE_NAME = my-app

K8S_DIR ?= .infra/k8s
IMAGE_NAME ?= $(APP_NAME)

export K8S_DIR
export IMAGE_NAME

.PHONY: infra.apply infra.staging.apply infra.production.apply deploy.staging deploy.development deploy.production k8s.init k8s.login k8s.context k8s.context.list k8s.namespaces k8s.namespaces.use k8s.pods k8s.pods.staging k8s.pods.production console.staging console.production console.staging.fullaccess console.production.fullaccess db.ip.allow registry.login

### Registry - Authenticate with AWS ECR via SSO
registry.login:
	@$(COMMONS_DIR)/shell/tasks/infra/registry/login.sh


### Infra - Apply (asks for environment)
infra.apply:
	@$(COMMONS_DIR)/shell/tasks/infra/apply.sh

### Infra Staging - terraform apply + deploy
infra.staging.apply:
	$(MAKE) terraform.staging.apply
	$(MAKE) deploy.staging

### Infra Production - terraform apply + deploy
infra.production.apply:
	$(MAKE) terraform.production.apply
	$(MAKE) deploy.production

### Deploy staging: interactive menu to select and apply a versioned tag (no build)
deploy.staging:
	@$(COMMONS_DIR)/shell/tasks/infra/deploy/staging.sh

### Deploy development: build linux/amd64 + push + kubectl apply with dev-{user}-{hash} tag
deploy.development:
	@$(COMMONS_DIR)/shell/tasks/infra/deploy/development.sh

### Deploy production: kubectl apply (requires production kubeconfig + RBAC permission)
deploy.production:
	@$(COMMONS_DIR)/shell/tasks/infra/deploy/production.sh

### K8s init: setup EKS auth + generate IAM contexts (run once). Devops can impersonate: make k8s.init K8S_USER=matheus
k8s.init:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/context/setup.sh init $(K8S_USER)

### K8s login: renew EKS credentials (use when k9s/kubectl reports session expired)
k8s.login:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/context/login.sh

### K8s context: switch between developer and infra contexts interactively
k8s.context:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/context/change.sh $(PROFILE)

### K8s context list: show all configured contexts and summary
k8s.context.list:
	@bash $(COMMONS_DIR)/shell/tasks/infra/k8s/context/summary.sh

### K8s namespaces: list accessible namespaces in current context
k8s.namespaces:
	@bash $(COMMONS_DIR)/shell/tasks/infra/k8s/namespace.sh list

### K8s namespaces use: switch active namespace (interactive or NS=<name>)
k8s.namespaces.use:
	@bash $(COMMONS_DIR)/shell/tasks/infra/k8s/namespace.sh use $(NS)

### K8s pods: list pods interactively (asks env + namespace)
k8s.pods:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/pods.sh

### K8s pods staging: list pods in accessible staging namespaces
k8s.pods.staging:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/pods.sh staging

### K8s pods production: list pods in accessible production namespaces
k8s.pods.production:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/pods.sh production

### Console on staging pod (requires run/console in the project)
console.staging:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/console.sh staging

### Console on production pod (requires run/console in the project)
console.production:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/console.sh production

### Console on staging pod with full DB access
console.staging.fullaccess:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/console.sh staging --admin

### Console on production pod with full DB access (requires developer-owner context)
console.production.fullaccess:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/console.sh production --admin

### Shell on staging: temporary pod with sh for debugging
shell.staging:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/shell.sh staging

### Shell on production: temporary pod with sh for debugging
shell.production:
	@$(COMMONS_DIR)/shell/tasks/infra/k8s/shell.sh production

### DB ip allow: authorize current (or IP=) public IP on the database security group
db.ip.allow:
	@$(COMMONS_DIR)/shell/tasks/infra/db/ip/allow.sh $(IP)
