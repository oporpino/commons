#!/usr/bin/env bash
set -euo pipefail

if [ ! -d ".commons" ]; then
  echo "Execute a partir da raiz do projeto"
  exit 1
fi

if [ ! -d ".commons/ai/skills" ] || [ ! -d ".commons/ai/commands" ]; then
  echo "Rode: git submodule update --init"
  exit 1
fi

mkdir -p .claude

clean_target() {
  local target="$1"

  if [ -L "$target" ] || [ -d "$target" ]; then
    printf "Remover $target antes de recriar o symlink? [s/N] "
    read -r answer
    if [ "$answer" != "s" ] && [ "$answer" != "S" ]; then
      echo "Cancelado."
      exit 0
    fi
    rm -rf "$target"
    echo "✓ $target removido"
  fi
}

symlink() {
  local target="$1"
  local dest="$2"

  ln -s "$dest" "$target"
  echo "✓ $target -> $dest"
}

# Skills: .claude/skills aponta direto para .commons/ai/skills
clean_target ".claude/skills"
symlink ".claude/skills" "../.commons/ai/skills"

# Commands: dois namespaces em .claude/commands/
#   project/ -> commands específicos do projeto
#   commons/ -> commands compartilhados da org
clean_target ".claude/commands"
mkdir -p .claude/commands
mkdir -p .project/ai/commands
symlink ".claude/commands/project" "../../.project/ai/commands"
symlink ".claude/commands/commons" "../../.commons/ai/commands"
