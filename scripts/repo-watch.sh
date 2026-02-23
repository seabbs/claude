#!/usr/bin/env bash
# repo-watch.sh — Detect active repos not cloned locally
# Usage: repo-watch.sh [org-name]
# Checks GitHub for repos where owner has recent activity
# Outputs JSON of repos that should be cloned

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

CODE_DIR="${CODE_DIR:-$HOME/code}"
ORGS="${@:-epinowcast epiforecasts EpiAware nfidd seabbs}"

# Resolve owner from first org config or env
OWNER_USER="${OWNER_USER:-}"
for _org_dir in "$CODE_DIR"/*/; do
  _cm="$_org_dir/CLAUDE.md"
  [[ ! -f "$_cm" ]] && continue
  [[ -z "$OWNER_USER" ]] && \
    OWNER_USER=$(get_org_config "$_cm" "owner_account" "")
  [[ -n "$OWNER_USER" ]] && break
done
OWNER_USER="${OWNER_USER:-seabbs}"

echo "{"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo '  "missing_repos": ['

first=true
for org in $ORGS; do
  CLAUDE_MD="$CODE_DIR/$org/CLAUDE.md"

  # Get locally known repos
  local_repos=""
  if [[ -f "$CLAUDE_MD" ]]; then
    local_repos=$(parse_repo_names "$CLAUDE_MD" | tr '\n' '|')

    # Check for excluded repos in CLAUDE.md
    excluded=""
    if grep -q '## Excluded repos' "$CLAUDE_MD" 2>/dev/null; then
      excluded=$(sed -n '/## Excluded repos/,/^## /p' "$CLAUDE_MD" \
        | grep '^\- ' | sed 's/^- //' | tr '\n' '|')
    fi
  fi

  gh_org="$org"
  if [[ -f "$CLAUDE_MD" ]]; then
    gh_org=$(get_gh_org "$CLAUDE_MD" "$org")
  fi

  # List GitHub repos for this org
  gh_repos=$(gh repo list "$gh_org" --limit 200 \
    --json name,isArchived,pushedAt,owner \
    --jq '.[] | select(.isArchived == false)' \
    2>/dev/null || echo "")

  [[ -z "$gh_repos" ]] && continue

  # Check each repo for seabbs activity
  while IFS= read -r repo_json; do
    repo_name=$(echo "$repo_json" | jq -r '.name')
    pushed_at=$(echo "$repo_json" | jq -r '.pushedAt')

    # Skip if already local
    if echo "$local_repos" | grep -q "$repo_name"; then
      continue
    fi

    # Skip if excluded
    if [[ -n "${excluded:-}" ]] && echo "$excluded" | grep -q "$repo_name"; then
      continue
    fi

    # Skip if not pushed in 90 days
    pushed_epoch=$(date -d "$pushed_at" +%s 2>/dev/null \
      || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$pushed_at" +%s 2>/dev/null \
      || echo 0)
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - pushed_epoch) / 86400 ))
    [[ $age_days -gt 90 ]] && continue

    # Check if seabbs has recent activity (issues, PRs, commits)
    has_activity=false

    # Check for open issues by or assigned to seabbs
    issue_count=$(gh api "repos/$gh_org/$repo_name/issues?assignee=$OWNER_USER&state=open" \
      --jq 'length' 2>/dev/null || echo 0)
    [[ "$issue_count" -gt 0 ]] && has_activity=true

    # Check for open PRs by seabbs
    if ! $has_activity; then
      pr_count=$(gh pr list --author "$OWNER_USER" --state open \
        -R "$gh_org/$repo_name" --json number --jq 'length' \
        2>/dev/null || echo 0)
      [[ "$pr_count" -gt 0 ]] && has_activity=true
    fi

    # Check for recent reviews by seabbs
    if ! $has_activity; then
      review_count=$(gh api "repos/$gh_org/$repo_name/pulls?state=open" \
        --jq "[.[] | select(.requested_reviewers[]?.login == \"$OWNER_USER\")] | length" \
        2>/dev/null || echo 0)
      [[ "$review_count" -gt 0 ]] && has_activity=true
    fi

    if $has_activity; then
      if $first; then first=false; else echo ","; fi
      jq -n \
        --arg org "$org" \
        --arg gh_org "$gh_org" \
        --arg repo "$repo_name" \
        --arg pushed "$pushed_at" \
        --argjson issues "$issue_count" \
        '{org: $org, gh_org: $gh_org, repo: $repo, last_push: $pushed, open_issues_assigned: $issues}'
    fi
  done < <(echo "$gh_repos" | jq -c '.')
done

echo '  ]'
echo "}"
