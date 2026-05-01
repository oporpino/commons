#!/usr/bin/env bash
# Module: commons
# Sets up shell utilities from the commons repo

MODULE_NAME="commons"

_commons_print() {
    echo "│  $*"
}

_commons_print "Setting up commons utilities..."

SHELL_SCRIPTS_DIR="$COMMONS_DIR/scripts/shell"
SHELL_RC="$HOME/.zshrc"

if [ -n "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

COMMONS_INIT_BLOCK="# WeHive commons — added by init.sh
export COMMONS_DIR=\"$COMMONS_DIR\"
export PATH=\"\$COMMONS_DIR/scripts/shell:\$PATH\""

if grep -qF "WeHive commons" "$SHELL_RC" 2>/dev/null; then
    _commons_print "Shell config already up to date in $SHELL_RC"
else
    {
        echo
        echo "$COMMONS_INIT_BLOCK"
    } >> "$SHELL_RC"
    _commons_print "Added commons to $SHELL_RC"
fi

export COMMONS_DIR="$COMMONS_DIR"
export PATH="$SHELL_SCRIPTS_DIR:$PATH"

_commons_print "Done."
