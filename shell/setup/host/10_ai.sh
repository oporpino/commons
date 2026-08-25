#!/bin/bash -e

. "${COMMONS_DIR}/shell/helpers/setup.sh"

clean() {
  local target="$1"
  { [ -L "$target" ] || [ -d "$target" ]; } && rm -rf "$target"
}

unignore_ai_links() {
  [ -f ".gitignore" ] || return 0

  sed -i.bak \
    -e '/^\.claude$/d' \
    -e '/^\.claude\/$/d' \
    -e '/^\.claude\/\*$/d' \
    -e '/^\.claude\/skills$/d' \
    -e '/^\.claude\/commands$/d' \
    -e '/^!\.claude\/$/d' \
    -e '/^!\.claude\/skills$/d' \
    -e '/^!\.claude\/commands$/d' \
    -e '/^\.codex$/d' \
    -e '/^\.codex\/$/d' \
    -e '/^\.codex\/\*$/d' \
    -e '/^\.codex\/skills$/d' \
    -e '/^\.codex\/commands$/d' \
    -e '/^!\.codex\/$/d' \
    -e '/^!\.codex\/skills$/d' \
    -e '/^!\.codex\/commands$/d' \
    -e '/^\.project\/ai\/skills$/d' \
    -e '/^\.project\/ai\/commands$/d' \
    ".gitignore"
  rm -f ".gitignore.bak"

  {
    echo ".claude/*"
    echo "!.claude/"
    echo "!.claude/skills"
    echo "!.claude/commands"
    echo ".codex/*"
    echo "!.codex/"
    echo "!.codex/skills"
    echo "!.codex/commands"
  } >> ".gitignore"
}

clean ".claude/skills/wehive"
clean ".claude/skills"
clean ".claude/commands"
clean ".codex/skills"
clean ".codex/commands"

mkdir -p ".project/ai/skills" ".project/ai/commands" ".claude" ".codex"
touch ".project/ai/skills/.gitkeep" ".project/ai/commands/.gitkeep"
ln -s "../.project/ai/skills" ".claude/skills"
ln -s "../.project/ai/commands" ".claude/commands"
ln -s "../.project/ai/skills" ".codex/skills"
ln -s "../.project/ai/commands" ".codex/commands"
unignore_ai_links

printf "  ✔ setup ai folders\n"
