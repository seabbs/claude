#!/usr/bin/env bash
# _lib.sh — Shared functions for org helper scripts
# Source this from other scripts: source "$(dirname "$0")/_lib.sh"

# Read a value from the "## Automation config" table in
# an org's CLAUDE.md. Falls back to a default if not found.
# Usage: get_org_config <claude_md> <key> [default]
#
# Expected format in CLAUDE.md:
#   ## Automation config
#   | Setting | Value |
#   |---|---|
#   | bot_account | seabbs-bot |
#   | owner_account | seabbs |
get_org_config() {
  local claude_md="$1"
  local key="$2"
  local default="${3:-}"
  local val=""
  if [[ -f "$claude_md" ]]; then
    val=$(awk -F'|' -v k="$key" '
      /^## Automation config/ { found=1; next }
      found && /^## / { found=0 }
      found && $0 ~ "\\| *" k " *\\|" {
        gsub(/^[ \t]+|[ \t]+$/, "", $3)
        print $3
        exit
      }
    ' "$claude_md")
  fi
  echo "${val:-$default}"
}

# Extract GitHub org/user name from a CLAUDE.md file
# Falls back to the folder name if not found
get_gh_org() {
  local claude_md="$1"
  local fallback="$2"
  local gh_org=""
  gh_org=$(sed -n 's/.*github\.com\/\([^)]*\)).*/\1/p' "$claude_md" \
    | head -1)
  if [[ -z "$gh_org" ]]; then
    gh_org="$fallback"
  fi
  echo "$gh_org"
}

# Parse repo names from a CLAUDE.md "Local repos" or "Repos" table
# Output: one repo name per line
parse_repo_names() {
  local claude_md="$1"
  local in_local=false
  while IFS= read -r line; do
    if [[ "$line" == *"## Local repos"* ]] || \
       [[ "$line" == *"## Repos"* ]]; then
      in_local=true
      continue
    fi
    if $in_local && [[ "$line" == "## "* ]]; then
      break
    fi
    if $in_local && [[ "$line" == "|"* ]]; then
      local name
      name=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
      [[ "$name" == "Repo" ]] && continue
      [[ "$name" == "-"* ]] && continue
      [[ -z "$name" ]] && continue
      echo "$name"
    fi
  done < "$claude_md"
}

# Parse repo names with types from a CLAUDE.md table
# Output: name|type per line
parse_repo_names_with_type() {
  local claude_md="$1"
  local in_local=false
  while IFS= read -r line; do
    if [[ "$line" == *"## Local repos"* ]] || \
       [[ "$line" == *"## Repos"* ]]; then
      in_local=true
      continue
    fi
    if $in_local && [[ "$line" == "## "* ]]; then
      break
    fi
    if $in_local && [[ "$line" == "|"* ]]; then
      local name type
      name=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
      type=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
      [[ "$name" == "Repo" ]] && continue
      [[ "$name" == "-"* ]] && continue
      [[ -z "$name" ]] && continue
      echo "$name|$type"
    fi
  done < "$claude_md"
}
