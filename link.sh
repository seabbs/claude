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

link "CLAUDE.md"  "$HOME/.claude/CLAUDE.md"
link "commands"   "$HOME/.claude/commands"

echo "Done."
echo "Run ~/.claude/setup.sh to install plugins."
