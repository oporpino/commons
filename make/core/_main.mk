
.SILENT:
-include .env

APP_NAME ?= $(notdir $(CURDIR))
PROJECT_DIR ?= $(CURDIR)
CONTAINER_REGISTRY ?=
DEV_MODE ?= container
DEV_DEPENDENCIES ?= start

export APP_NAME
export PROJECT_DIR
export CONTAINER_REGISTRY
export DEV_MODE
export DEV_DEPENDENCIES
export DATABASE_URL_STAGING
export DATABASE_URL_PRODUCTION

_runner = $(COMMONS_DIR)/shell/helpers/devmode/runner.sh

.DEFAULT_GOAL := help

<<<<<<< HEAD
include $(COMMONS_DIR)/make/core/commands.mk
||||||| parent of d59c1d0 (feat: add dev mode start dispatcher)
# core includes
include $(COMMONS_DIR)/make/core/_contract.mk
include $(COMMONS_DIR)/make/core/_container.mk
include $(COMMONS_DIR)/make/core/_shortcuts.mk
=======
# core includes
include $(COMMONS_DIR)/make/core/_contract.mk
include $(COMMONS_DIR)/make/core/_container.mk
include $(COMMONS_DIR)/make/core/start.mk
include $(COMMONS_DIR)/make/core/_shortcuts.mk
>>>>>>> d59c1d0 (feat: add dev mode start dispatcher)
include $(COMMONS_DIR)/make/core/help.mk
include $(COMMONS_DIR)/make/core/release.mk
include $(COMMONS_DIR)/make/core/commons.mk
include $(COMMONS_DIR)/make/core/setup.mk
include $(COMMONS_DIR)/make/core/container.mk

# build, prune, etc.
include $(COMMONS_DIR)/make/core/compose.mk
include $(COMMONS_DIR)/make/core/image.mk

-include $(COMMONS_DIR)/make/shared/infra.mk
-include $(COMMONS_DIR)/make/shared/deploy.mk

# ------------------------------------------------------------------------------
# shortcuts
# ------------------------------------------------------------------------------
up: _compose.up ### Start all services and follow logs
up.detached: _compose.up.attached ### Start all services in background
build: _compose.build ### Rebuild images without cache
logs: _compose.logs ### Follow service logs
stats: _compose.stats ### Show container CPU/memory usage
stop: _compose.stop ### Stop containers
down: _compose.down ### Stop and remove containers and volumes
clear: _compose.clear ### Remove containers and volumes, keep images
prune: _compose.prune ### Remove project containers, volumes and images
prune.images: _compose.prune.images ### Remove project images only
prune.cache: _compose.prune.cache ### Clear docker build cache
image.dev.push: _image.dev.push ### Push dev image to registry
image.dev.push.all: _image.dev.push.all ### Push dev images for all stacks
image.dev.pull: _image.dev.pull ### Pull dev image from registry
