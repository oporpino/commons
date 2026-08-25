#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

if [ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
  tmp="$(mktemp)"
  if ! RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >"$tmp" 2>&1; then
    cat "$tmp" >&2
    rm -f "$tmp"
    exit 1
  fi
  rm -f "$tmp"
fi

touch ~/.zshrc

if ! grep -q "# WeHive history configuration" ~/.zshrc; then
  cat >> ~/.zshrc << 'EOL'

# WeHive history configuration
# History configuration
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
unsetopt share_history
setopt inc_append_history
setopt append_history
EOL
fi
