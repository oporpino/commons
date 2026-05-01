#!/usr/bin/env bash

COMMONS_REPO="oporpino/commons"
COMMONS_BRANCH="main"
DEFAULT_WORKSPACE="$HOME/workspace/"
DEFAULT_FOLDER="wehive.tech"

MODULES=(commons tools claude registry k8s)
MODULE_COUNT=${#MODULES[@]}

SEP="========================================"
BOX_WIDTH=56

_dashes() {
    printf '─%.0s' $(seq 1 $BOX_WIDTH)
}

print_header() {
    echo "$SEP"
    echo "WeHive Environment Setup"
    echo "$SEP"
    echo
}

print_footer() {
    echo
    echo "$SEP"
    echo "WeHive environment setup complete!"
    echo "$SEP"
    echo
    echo "  Summary"
    echo "  $(_dashes)"
    echo
    echo "Run 'source ~/.zshrc' to apply shell changes."
    echo
}

open_module_box() {
    local index="$1"
    local total="$2"
    echo
    echo "╭─ [$index/$total]"
    echo "│"
}

close_module_box() {
    echo -n "╰"
    _dashes
    echo
}

# ── Main ──────────────────────────────────────────────────

print_header

echo "  Projects will be installed in:"
echo "  $DEFAULT_WORKSPACE"
read -rp "  Folder name [$DEFAULT_FOLDER]: " FOLDER_NAME
FOLDER_NAME="${FOLDER_NAME:-$DEFAULT_FOLDER}"

WORKSPACE_DIR="${DEFAULT_WORKSPACE%/}"
PROJECT_DIR="$WORKSPACE_DIR/$FOLDER_NAME"
COMMONS_DIR="$PROJECT_DIR/.commons"

mkdir -p "$PROJECT_DIR"

if [ -d "$COMMONS_DIR/.git" ]; then
    git -C "$COMMONS_DIR" pull origin "$COMMONS_BRANCH" --quiet 2>/dev/null || true
else
    git clone "https://github.com/$COMMONS_REPO.git" "$COMMONS_DIR" \
        --branch "$COMMONS_BRANCH" --depth 1 --quiet 2>/dev/null || \
    git clone "git@github.com:$COMMONS_REPO.git" "$COMMONS_DIR" \
        --branch "$COMMONS_BRANCH" --depth 1 --quiet
fi

for i in "${!MODULES[@]}"; do
    module="${MODULES[$i]}"
    index=$((i + 1))
    MODULE_FILE="$COMMONS_DIR/environment/init/modules/$module/module.sh"

    open_module_box "$index" "$MODULE_COUNT"
    # shellcheck source=/dev/null
    source "$MODULE_FILE"
    close_module_box
done

print_footer
