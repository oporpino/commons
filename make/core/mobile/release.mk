
# aliases
release: _release.mobile.create
release.android: _release.mobile.android
release.ios: _release.mobile.ios

# release management
_release.mobile.create:
	@$(COMMONS_DIR)/shell/tasks/release/mobile.sh

_release.mobile.android:
	@$(COMMONS_DIR)/shell/tasks/release/mobile.sh --android

_release.mobile.ios:
	@$(COMMONS_DIR)/shell/tasks/release/mobile.sh --ios

release.patch:
	@$(COMMONS_DIR)/shell/tasks/release/mobile.sh --patch --auto-approve

release.android.patch:
	@$(COMMONS_DIR)/shell/tasks/release/mobile.sh --android --patch --auto-approve

release.ios.patch:
	@$(COMMONS_DIR)/shell/tasks/release/mobile.sh --ios --patch --auto-approve
