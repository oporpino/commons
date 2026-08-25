
# compose
start.attached = make _compose.start.attached
start.attached:
	$(start.attached)

stop = make _compose.stop
stop:
	$(stop)

build = make _compose.build
build b:
	$(build)

restart = make _compose.restart
restart:
	$(restart)

logs = make _compose.logs
logs:
	$(logs)

down = make _compose.down
down:
	$(down)

clear = make _compose.clear
clear:
	$(clear)

prune = make _compose.prune
prune:
	$(prune)

prune.images = make _compose.prune.images
prune.images:
	$(prune.images)

prune.cache = make _compose.prune.cache
prune.cache:
	$(prune.cache)

# image registry
image.dev.push = make _compose.image.dev.push
image.dev.push:
	$(image.dev.push)

image.dev.push.all = make _compose.image.dev.push.all
image.dev.push.all:
	$(image.dev.push.all)

image.dev.pull = make _compose.image.dev.pull
image.dev.pull:
	$(image.dev.pull)

# container
shell = make _container.app.shell
shell sh:
	$(shell)

install = make _container.app.install
install i:
	$(install)

lint = make _container.app.lint
lint:
	$(lint)

lint.fix = make _container.app.lint.fix
lint.fix:
	$(lint.fix)

ifneq ($(filter test t,$(firstword $(MAKECMDGOALS))),)
_test_args := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(if $(_test_args),$(eval $(_test_args):;@:))
endif

test = make _container.app.test path="$(or $(_test_args),$(path))"
test t:
	$(test)

test.watch = make _container.app.test.watch
test.watch tw:
	$(test.watch)

test.diff = make _container.app.test.diff
test.diff td:
	$(test.diff)

audit = make _container.app.audit
audit a:
	$(audit)

console = make _container.app.console
console:
	$(console)

ds: deploy.staging
