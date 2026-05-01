#!/usr/bin/env bash
# Module: k8s
# Sets up Kubernetes tools and configuration

_k8s_print() {
    echo "│  $*"
}

_k8s_brew_install() {
    local package="$1"
    if command -v "$package" &>/dev/null; then
        _k8s_print "✓ $package already installed"
    elif command -v brew &>/dev/null; then
        _k8s_print "  Installing $package..."
        brew install "$package" --quiet 2>/dev/null && \
            _k8s_print "✓ $package installed" || \
            _k8s_print "✗ Failed to install $package"
    else
        _k8s_print "✗ $package not found and brew is unavailable"
    fi
}

_k8s_print "Setting up Kubernetes tools..."

_k8s_brew_install kubectl
_k8s_brew_install helm

# Kubeconfig
KUBECONFIG_DIR="$HOME/.kube"
mkdir -p "$KUBECONFIG_DIR"

KUBECONFIG_ENV="${WEHIVE_KUBECONFIG:-}"
if [ -n "$KUBECONFIG_ENV" ]; then
    echo "$KUBECONFIG_ENV" | base64 -d > "$KUBECONFIG_DIR/config" 2>/dev/null && \
        _k8s_print "✓ kubeconfig written to $KUBECONFIG_DIR/config" || \
        _k8s_print "✗ Failed to decode WEHIVE_KUBECONFIG"
elif [ -f "$KUBECONFIG_DIR/config" ]; then
    _k8s_print "✓ kubeconfig already exists at $KUBECONFIG_DIR/config"
else
    _k8s_print "⚠  No kubeconfig found"
    _k8s_print "   Set WEHIVE_KUBECONFIG (base64-encoded) to auto-configure kubectl"
fi

_k8s_print "Done."
