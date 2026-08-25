_CONTAINER_SHELL ?= sh

_container.app.shell:
	docker compose run --rm --remove-orphans app $(_CONTAINER_SHELL)

_container.app.install:
	docker compose run --rm --no-deps app make code.install

_container.app.lint:
	docker compose run --rm --remove-orphans app make code.lint

_container.app.lint.fix:
	docker compose run --rm --remove-orphans app make code.lint.fix

_container.app.test:
	docker compose run --rm --remove-orphans app make code.test path="$(path)"

_container.app.test.watch:
	docker compose run --rm --remove-orphans app sh -c "make code.test.watch"

_container.app.test.diff:
	docker compose run --rm --no-deps app sh -c "make code.test.diff"

_container.app.audit:
	docker compose run --rm --remove-orphans app make code.audit

_container.app.console:
	docker compose run --rm --remove-orphans app make code.console

_container.start:
	@$(MAKE) _compose.start
