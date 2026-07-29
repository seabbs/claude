#!/bin/bash
# link.sh — Symlink Claude Code config into ~/.claude/
# Called from dotfiles/scripts/link.sh or run standalone.

set -euo pipefail

CLAUDE_DIR="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$CLAUDE_DIR/$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "  $dst -> $src"
}

echo "Linking Claude Code config from $CLAUDE_DIR"

link "CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "settings.json"  "$HOME/.claude/settings.json"
link "commands"        "$HOME/.claude/commands"
link "hooks"           "$HOME/.claude/hooks"
# Skills are linked one by one: ~/.claude/skills also holds skills that
# install scripts write, so the directory itself must not be a symlink.
link "skills/julia-repl" "$HOME/.claude/skills/julia-repl"

echo "Done."
echo "Run ~/.claude/setup.sh to install plugins."
