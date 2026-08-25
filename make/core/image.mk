### Build and push a base dev image. Reads stack/version from .tool-versions; env vars override.
### Usage: make image.dev.push [STACK=ruby] [STACK_VERSION=3.4] [DISTRO=alpine]
_image.dev.push:
	@STACK="$(STACK)" STACK_VERSION="$(STACK_VERSION)" DISTRO="$(or $(DISTRO),alpine)" \
	  bash $(COMMONS_DIR)/shell/tasks/docker/image/push.sh

### Build and push base dev images for all stacks found in .tool-versions (asdf)
_image.dev.push.all:
	@DISTRO="$(or $(DISTRO),alpine)" bash $(COMMONS_DIR)/shell/tasks/docker/image/push-all.sh

### Pull the latest dev image from the registry (force, no cache)
_image.dev.pull:
	@STACK="$(STACK)" STACK_VERSION="$(STACK_VERSION)" DISTRO="$(or $(DISTRO),alpine)" \
	  bash $(COMMONS_DIR)/shell/tasks/docker/image/pull.sh
