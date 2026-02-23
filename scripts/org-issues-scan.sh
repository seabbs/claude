#!/usr/bin/env bash
# org-issues-scan.sh — Collect open issues with metadata across an org
# Usage: org-issues-scan.sh <org-name> [repo-name]
# Used by /org-issues-tidy and /org-issues-do
# Outputs JSON array of issues with labels, author info, bot comment status

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

ORG="${1:?Usage: org-issues-scan.sh <org-name> [repo-name]}"
REPO_FILTER="${2:-}"
CODE_DIR="${CODE_DIR:-$HOME/code}"
CLAUDE_MD="$CODE_DIR/$ORG/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "Error: $CLAUDE_MD not found" >&2
  exit 1
fi

gh_org=$(get_gh_org "$CLAUDE_MD" "$ORG")
BOT_USER=$(get_org_config "$CLAUDE_MD" "bot_account" \
  "${BOT_USER:-seabbs-bot}")

# Build repo list
repos=()
if [[ -n "$REPO_FILTER" ]]; then
  repos=("$REPO_FILTER")
else
  while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")
fi

echo "["
first=true
for repo in "${repos[@]}"; do
  # Fetch open issues
  issues=$(gh issue list \
    --state open \
    -R "$gh_org/$repo" \
    --json number,title,url,labels,createdAt,updatedAt,author,assignees \
    --limit 50 2>/dev/null || echo "[]")

  [[ "$issues" == "[]" ]] && continue

  count=$(echo "$issues" | jq length)
  for ((j = 0; j < count; j++)); do
    issue=$(echo "$issues" | jq ".[$j]")
    number=$(echo "$issue" | jq -r '.number')

    # Check author association
    author_assoc=$(gh api "repos/$gh_org/$repo/issues/$number" \
      --jq '.author_association' 2>/dev/null || echo "NONE")

    # Check if seabbs-bot has already commented
    bot_commented=$(gh api "repos/$gh_org/$repo/issues/$number/comments" \
      --jq '[.[] | select(.user.login == "'"$BOT_USER"'")] | length' \
      2>/dev/null || echo 0)

    # Check if there's a linked PR
    has_linked_pr=$(gh api "repos/$gh_org/$repo/issues/$number/timeline" \
      --jq '[.[] | select(.event == "cross-referenced" and .source.issue.pull_request != null)] | length' \
      2>/dev/null || echo 0)

    # Get label names
    labels=$(echo "$issue" | jq '[.labels[].name]')

    # Check if assigned
    assigned=$(echo "$issue" | jq '.assignees | length > 0')

    if $first; then first=false; else echo ","; fi
    echo "$issue" | jq \
      --arg repo "$repo" \
      --arg gh_org "$gh_org" \
      --arg author_assoc "$author_assoc" \
      --argjson bot_commented "$bot_commented" \
      --argjson has_linked_pr "$has_linked_pr" \
      --argjson assigned "$assigned" \
      '. + {
        repo: $repo,
        gh_org: $gh_org,
        author_association: $author_assoc,
        bot_commented: ($bot_commented > 0),
        has_linked_pr: ($has_linked_pr > 0),
        is_assigned: $assigned
      }'
  done
done
echo "]"
