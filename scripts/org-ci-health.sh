#!/usr/bin/env bash
# org-ci-health.sh — Collect CI status across repos in an org
# Usage: org-ci-health.sh <org-name>
# Outputs JSON array of per-repo CI info to stdout

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

ORG="${1:?Usage: org-ci-health.sh <org-name>}"
CODE_DIR="${CODE_DIR:-$HOME/code}"
CLAUDE_MD="$CODE_DIR/$ORG/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "Error: $CLAUDE_MD not found" >&2
  exit 1
fi

gh_org=$(get_gh_org "$CLAUDE_MD" "$ORG")
repos=()
while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

echo "["
first=true
for repo in "${repos[@]}"; do
  if $first; then first=false; else echo ","; fi

  # Check if repo has workflows
  has_workflows=false
  workflow_dir="$CODE_DIR/$ORG/$repo/.github/workflows"
  if [[ -d "$workflow_dir" ]]; then
    has_workflows=true
  fi

  # Get latest CI runs on main/default branch
  runs_json=$(gh run list \
    -R "$gh_org/$repo" \
    --branch main \
    --limit 5 \
    --json status,conclusion,name,createdAt,event \
    2>/dev/null || echo "[]")

  # Get action versions used in workflows
  actions_used="[]"
  if $has_workflows; then
    actions_used=$(grep -rh 'uses:' "$workflow_dir" 2>/dev/null \
      | sed 's/.*uses:[[:space:]]*//' \
      | sed 's/[[:space:]]*#.*//' \
      | sort -u \
      | jq -R -s 'split("\n") | map(select(. != ""))' \
      2>/dev/null || echo "[]")
  fi

  cat <<ENTRY
  {
    "repo": "$repo",
    "gh_org": "$gh_org",
    "has_workflows": $has_workflows,
    "recent_runs": $runs_json,
    "actions_used": $actions_used
  }
ENTRY
done
echo "]"
