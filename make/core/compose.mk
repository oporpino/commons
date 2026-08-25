
_docker.daemon.ensure:
	@docker info > /dev/null 2>&1 && exit 0; \
	  colima start 2>&1 || true; \
	  for i in $$(seq 1 15); do docker info > /dev/null 2>&1 && exit 0; sleep 1; done; \
	  echo "error: docker daemon unavailable — try: colima delete && colima start" && exit 1

_build.args.env = eval "$$(sh $(COMMONS_DIR)/shell/helpers/devmode/load-build-args.sh)" ;
_compose.env = $(strip $(_build.args.env))

### Up docker compose services (detached + follow logs)
_compose.up: _docker.daemon.ensure
	@$(strip $(_compose.env)) docker compose up --build --remove-orphans -d $$(docker compose config --services | awk '!/^x-/')
	@$(strip $(_compose.env)) docker compose logs -f

### Up docker compose services in attached mode
_compose.up.attached: _docker.daemon.ensure
	@$(strip $(_compose.env)) docker compose up --build --remove-orphans $$(docker compose config --services | awk '!/^x-/')

### Stop docker compose services
_compose.stop:
	@$(strip $(_compose.env)) docker compose stop

### Stop and remove docker compose services
_compose.down: _docker.daemon.ensure
	@$(strip $(_compose.env)) docker compose down --volumes --remove-orphans

### Restart docker compose services
_compose.restart:
	@$(strip $(_compose.env)) docker compose restart

### Show docker compose logs
_compose.logs:
	@$(strip $(_compose.env)) docker compose logs -f

### Show docker stats for docker compose services
_compose.stats:
	@$(strip $(_compose.env)) docker stats --no-stream $$(docker compose ps -q)

### Build docker compose services without cache
_compose.build: _docker.daemon.ensure
	@$(strip $(_compose.env)) bash $(COMMONS_DIR)/shell/tasks/docker/registry-login.sh
	@$(strip $(_compose.env)) docker compose build --no-cache $$(docker compose config --services | awk '!/^x-/')

### Stop and remove containers and volumes (keeps images)
_compose.clear: _docker.daemon.ensure
	@echo "Stopping and removing containers and volumes..."
	@$(strip $(_compose.env)) docker compose down --volumes --remove-orphans
	@echo "Done."

### Prune images only
_compose.prune.images:
	@echo "Removing images..."
	docker compose down --rmi all --remove-orphans
	@echo "Done."

### Prune builder cache only
_compose.prune.cache:
	@echo "Pruning builder cache..."
	docker builder prune -a -f
	@echo "Done."

### Prune everything (containers, volumes, images, builder cache)
_compose.prune: _docker.daemon.ensure
	@echo "Pruning everything..."
	@$(strip $(_compose.env)) docker compose down --volumes --rmi all --remove-orphans
	docker builder prune -a -f
	@echo "Done."
