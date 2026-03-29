.PHONY: git.add git.commit git.pull git.update git.status ai.setup

PORT ?= 3000

git.add:
	@bash scripts/make/core/git/add.sh

git.commit:
	@bash scripts/make/core/git/commit.sh

git.pull:
	@bash scripts/make/core/git/pull.sh

git.update:
	@bash scripts/make/core/git/update.sh

git.status:
	@bash scripts/make/core/git/status.sh

ai.setup:
	@bash scripts/make/core/ai/setup.sh

release:
	@bash scripts/make/core/release.sh

release.patch:
	@bash scripts/make/core/release.sh --patch --auto-approve
