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

  echo ""
  echo "Done. Restart Claude Code to load updates."
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
