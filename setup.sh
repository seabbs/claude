#!/bin/bash
# setup.sh — Install or update Claude Code plugins
# Usage: setup.sh          # first-time install
#        setup.sh --update  # update all plugins to latest

set -euo pipefail

plugins=(
  research-academic
  lang-r
  lang-julia
  lang-stan
  dev-workflow
  github-ops
  org-management
  bot-automation
  productivity
)

update() {
  echo "Updating Claude Code plugins..."

  echo "Refreshing marketplaces..."
  claude plugin marketplace update skills || \
    echo "  Warning: failed to refresh skills marketplace"

  echo "Updating plugins..."
  for plugin in "${plugins[@]}"; do
    echo "  ${plugin}@skills..."
    claude plugin update "${plugin}@skills" || \
      echo "  Warning: failed to update ${plugin}"
  done

  claude plugin update humanizer@anthropic-agent-skills || \
    echo "  Warning: failed to update humanizer"

  mcp_servers

  echo ""
  echo "Done. Restart Claude Code to load updates."
}

# MCP servers are NOT read from settings.json — the settings schema has no
# `mcpServers` key, and unknown keys are ignored silently, so declaring one
# there looks wired up while doing nothing. Register at user scope instead
# (state lands in ~/.claude.json, which is machine-local and untracked).
mcp_servers() {
  echo "Registering MCP servers..."

  if ! command -v qmd >/dev/null 2>&1; then
    echo "  Skipping qmd: not on PATH (installed by dotfiles/cli/setup.sh)"
    return
  fi

  if claude mcp get qmd >/dev/null 2>&1; then
    echo "  qmd already registered"
  else
    claude mcp add -s user qmd -- qmd mcp || \
      echo "  Warning: failed to register qmd"
  fi
}

install() {
  echo "Setting up Claude Code plugins..."

  echo "Adding skills marketplace..."
  claude plugin marketplace add seabbs/skills

  echo "Installing plugins from skills marketplace..."
  for plugin in "${plugins[@]}"; do
    echo "  ${plugin}@skills..."
    claude plugin install "${plugin}@skills" || \
      echo "  Warning: failed to install ${plugin}"
  done

  echo "Installing third-party plugins..."
  claude plugin install humanizer@anthropic-agent-skills || \
    echo "  Warning: failed to install humanizer"

  echo ""
  echo "Done. Restart Claude Code to load new plugins."
  echo "Then run /setup-scripts to generate helper scripts."
}

case "${1:-}" in
  --update|-u) update ;;
  *)           install ;;
esac
