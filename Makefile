.PHONY: git.add git.commit git.pull git.update git.status help docker.prune

# Detect if we're running from inside .commons or from root
IS_COMMONS := $(shell basename $$(pwd) | grep -q "^.commons$$" && echo "true" || echo "false")
PORT ?= 3000

# Start the application
up:
	docker compose up --build --remove-orphans app

# Stop all containers
down:
	docker compose down

# Build the application
build:
	docker compose build app

# Clean up containers, networks, and volumes
clean: down
	docker compose down -v

# Start the project with dotnet watch
start:
	docker compose build app
	docker compose run --rm -p $(PORT):$(PORT) app

# Add files to git in main project and submodules
git.add:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/add
else
	@bash .commons/scripts/make/git/add
endif

# Commit changes in main project and submodules
git.commit:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/commit
else
	@bash .commons/scripts/make/git/commit
endif

# Pull changes in main project and submodules
git.pull:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/pull
else
	@bash .commons/scripts/make/git/pull
endif

# Update all modules
git.update:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/update
else
	@bash .commons/scripts/make/git/update
endif

# Show status of main project and submodules
git.status:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/git/status
else
	@bash .commons/scripts/make/git/status
endif

# Clean up all Docker System (containers, images, volumes, networks, and build cache)
docker.prune.all:
ifeq ($(IS_COMMONS),true)
	@bash scripts/shell/docker/prune-all
else
	@bash .commons/scripts/shell/docker/prune-all
endif

# Show help
help:
ifeq ($(IS_COMMONS),true)
	@bash scripts/make/help
else
	@bash .commons/scripts/make/help
endif
