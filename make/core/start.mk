DEV_MODE ?= container
export DEV_MODE

start = $(MAKE) _$(DEV_MODE).start
start s:
	$(start)

_local.start:
	@printf "\nStart Local Application ......................................................\n"
	@bin/start

_dependencies.start:
	@printf "\nStart Dependencies ..........................................................\n"
	@services=$$(docker compose config --services); \
	exclude=" install app worker beat migrations seed "; \
	deps=""; \
	for service in $$services; do \
	  case "$$exclude" in *" $$service "*) ;; \
	  *) deps="$$deps $$service";; \
	  esac; \
	done; \
	deps=$${deps# }; \
	if [ -z "$$deps" ]; then \
	  echo "No dependency services found"; \
	  exit 1; \
	fi; \
	docker compose up --build --remove-orphans $$deps
