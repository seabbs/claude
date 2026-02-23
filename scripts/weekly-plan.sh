#!/usr/bin/env bash
# weekly-plan.sh — Gather context for weekly planning
# Usage: weekly-plan.sh
# Collects: daily logs, open PRs, assigned issues, CI status
# Outputs JSON to stdout

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

CODE_DIR="${CODE_DIR:-$HOME/code}"
LOG_DIR="$CODE_DIR/claude-log"
ORGS=(epinowcast epiforecasts EpiAware nfidd seabbs)

# Resolve accounts from first org config
BOT_USER="${BOT_USER:-}"
OWNER_USER="${OWNER_USER:-}"
for org_dir in "$CODE_DIR"/*/; do
  cm="$org_dir/CLAUDE.md"
  [[ ! -f "$cm" ]] && continue
  [[ -z "$BOT_USER" ]] && \
    BOT_USER=$(get_org_config "$cm" "bot_account" "")
  [[ -z "$OWNER_USER" ]] && \
    OWNER_USER=$(get_org_config "$cm" "owner_account" "")
  [[ -n "$BOT_USER" ]] && [[ -n "$OWNER_USER" ]] && break
done
BOT_USER="${BOT_USER:-seabbs-bot}"
OWNER_USER="${OWNER_USER:-seabbs}"
TODAY=$(date +%Y-%m-%d)
WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null \
  || date -d "7 days ago" +%Y-%m-%d 2>/dev/null \
  || echo "$TODAY")

echo "{"
echo "  \"today\": \"$TODAY\","
echo "  \"week_start\": \"$WEEK_AGO\","

# --- Daily log files from past week ---
echo '  "daily_logs": ['
first=true
if [[ -d "$LOG_DIR" ]]; then
  for log in "$LOG_DIR"/*.md; do
    [[ ! -f "$log" ]] && continue
    log_date=$(basename "$log" .md)
    if [[ "$log_date" > "$WEEK_AGO" ]] || \
       [[ "$log_date" == "$WEEK_AGO" ]]; then
      if $first; then first=false; else echo ","; fi
      echo "    \"$log_date\""
    fi
  done
fi
echo '  ],'

# --- Open PRs by seabbs and seabbs-bot ---
echo '  "open_prs": ['
first=true
for org in "${ORGS[@]}"; do
  CLAUDE_MD="$CODE_DIR/$org/CLAUDE.md"
  [[ ! -f "$CLAUDE_MD" ]] && continue

  gh_org=$(get_gh_org "$CLAUDE_MD" "$org")
  repos=()
  while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

  for repo in "${repos[@]}"; do
    for author in "$OWNER_USER" "$BOT_USER"; do
      prs=$(gh pr list \
        --author "$author" \
        --state open \
        -R "$gh_org/$repo" \
        --json number,title,url,createdAt,updatedAt \
        2>/dev/null || echo "[]")
      if [[ "$prs" != "[]" ]] && [[ -n "$prs" ]]; then
        count=$(echo "$prs" | jq length)
        for ((j = 0; j < count; j++)); do
          if $first; then first=false; else echo ","; fi
          echo "    $(echo "$prs" | jq ".[$j]" \
            | jq --arg r "$gh_org/$repo" --arg a "$author" \
            '. + {repo: $r, author: $a}')"
        done
      fi
    done
  done
done
echo '  ],'

# --- Issues assigned to seabbs ---
echo '  "assigned_issues": ['
first=true
for org in "${ORGS[@]}"; do
  CLAUDE_MD="$CODE_DIR/$org/CLAUDE.md"
  [[ ! -f "$CLAUDE_MD" ]] && continue

  gh_org=$(get_gh_org "$CLAUDE_MD" "$org")
  repos=()
  while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

  for repo in "${repos[@]}"; do
    issues=$(gh issue list \
      --assignee "$OWNER_USER" \
      -R "$gh_org/$repo" \
      --json number,title,url,labels,milestone \
      --limit 50 2>/dev/null || echo "[]")
    if [[ "$issues" != "[]" ]] && [[ -n "$issues" ]]; then
      count=$(echo "$issues" | jq length)
      for ((j = 0; j < count; j++)); do
        if $first; then first=false; else echo ","; fi
        echo "    $(echo "$issues" | jq ".[$j]" \
          | jq --arg r "$gh_org/$repo" '. + {repo: $r}')"
      done
    fi
  done
done
echo '  ],'

# --- Recent git activity (commits in past week) ---
echo '  "recent_commits": {'
first_org=true
for org in "${ORGS[@]}"; do
  org_dir="$CODE_DIR/$org"
  [[ ! -d "$org_dir" ]] && continue
  has_commits=false
  commit_json=""

  for repo_dir in "$org_dir"/*/; do
    [[ ! -d "$repo_dir/.git" ]] && [[ ! -f "$repo_dir/.git" ]] && continue
    repo=$(basename "$repo_dir")

    count=$(git -C "$repo_dir" rev-list \
      --count --since="$WEEK_AGO" HEAD 2>/dev/null || echo 0)
    if [[ "$count" -gt 0 ]]; then
      has_commits=true
      if [[ -n "$commit_json" ]]; then
        commit_json="$commit_json, "
      fi
      commit_json="$commit_json\"$repo\": $count"
    fi
  done

  if $has_commits; then
    if $first_org; then first_org=false; else echo ","; fi
    echo "    \"$org\": {$commit_json}"
  fi
done
echo '  },'

# --- PRs merged this week ---
echo '  "prs_merged_this_week": '
merged=$(gh api search/issues --method GET \
  -f q="author:$BOT_USER type:pr is:merged merged:>=$WEEK_AGO" \
  --jq '.total_count' 2>/dev/null || echo 0)
echo "  $merged,"

# --- Issues closed this week ---
echo '  "issues_closed_this_week": '
closed=$(gh api search/issues --method GET \
  -f q="assignee:$OWNER_USER type:issue is:closed closed:>=$WEEK_AGO" \
  --jq '.total_count' 2>/dev/null || echo 0)
echo "  $closed"

echo "}"
