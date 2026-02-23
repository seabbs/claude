#!/bin/bash
# setup.sh — Install Claude Code plugins from marketplaces
# Run after link.sh to register marketplaces and install plugins.

set -euo pipefail

echo "Setting up Claude Code plugins..."

# Add our skills marketplace
echo "Adding skills marketplace..."
claude plugin marketplace add seabbs/skills

# Install our plugins
echo "Installing plugins from skills marketplace..."
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
for plugin in "${plugins[@]}"; do
  echo "  Installing ${plugin}@skills..."
  claude plugin install "${plugin}@skills" || \
    echo "  Warning: failed to install ${plugin}"
done

# Install third-party plugins
echo "Installing third-party plugins..."
claude plugin install humanizer@anthropic-agent-skills || \
  echo "  Warning: failed to install humanizer"

echo ""
echo "Done. Restart Claude Code to load new plugins."
echo "Then run /setup-scripts to generate helper scripts."
