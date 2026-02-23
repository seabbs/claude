#!/usr/bin/env bash
# daily-summary.sh — Collect bot activity for a given date
# Usage: daily-summary.sh [YYYY-MM-DD]
# Defaults to today. Outputs JSON to stdout.

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

DATE="${1:-$(date +%Y-%m-%d)}"
CODE_DIR="${CODE_DIR:-$HOME/code}"
ORGS=(epinowcast epiforecasts EpiAware nfidd seabbs)

# Resolve bot account from first org config
BOT_USER="${BOT_USER:-}"
for org_dir in "$CODE_DIR"/*/; do
  cm="$org_dir/CLAUDE.md"
  [[ ! -f "$cm" ]] && continue
  [[ -z "$BOT_USER" ]] && \
    BOT_USER=$(get_org_config "$cm" "bot_account" "")
  [[ -n "$BOT_USER" ]] && break
done
BOT_USER="${BOT_USER:-seabbs-bot}"

echo "{"
echo "  \"date\": \"$DATE\","

# --- PRs created or updated ---
echo '  "prs": ['
first=true
for org in "${ORGS[@]}"; do
  CLAUDE_MD="$CODE_DIR/$org/CLAUDE.md"
  [[ ! -f "$CLAUDE_MD" ]] && continue

  gh_org=$(get_gh_org "$CLAUDE_MD" "$org")
  repos=()
  while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

  for repo in "${repos[@]}"; do
    prs=$(gh pr list \
      --author "$BOT_USER" \
      --state all \
      --search "updated:>=$DATE" \
      -R "$gh_org/$repo" \
      --json number,title,state,url \
      --limit 50 2>/dev/null || echo "[]")

    if [[ "$prs" != "[]" ]] && [[ -n "$prs" ]]; then
      count=$(echo "$prs" | jq length)
      for ((j = 0; j < count; j++)); do
        if $first; then first=false; else echo ","; fi
        echo "    $(echo "$prs" | jq ".[$j]" \
          | jq --arg r "$gh_org/$repo" '. + {repo: $r}')"
      done
    fi
  done
done
echo '  ],'

# --- Issues commented on ---
echo '  "issues_commented": '
issues=$(gh api search/issues --method GET \
  -f q="commenter:$BOT_USER updated:>=$DATE" \
  --jq '.items | map({title, html_url, repository_url, state, number})' \
  2>/dev/null || echo "[]")
echo "  $issues,"

# --- Commits in local repos ---
echo '  "commits": ['
first=true
for org in "${ORGS[@]}"; do
  org_dir="$CODE_DIR/$org"
  [[ ! -d "$org_dir" ]] && continue
  for repo_dir in "$org_dir"/*/; do
    [[ ! -d "$repo_dir/.git" ]] && [[ ! -f "$repo_dir/.git" ]] && continue
    repo=$(basename "$repo_dir")

    commits=$(git -C "$repo_dir" log \
      --author="$BOT_USER" \
      --since="$DATE" \
      --format='%h %s' 2>/dev/null || true)
    [[ -z "$commits" ]] && continue

    while IFS= read -r commit_line; do
      [[ -z "$commit_line" ]] && continue
      hash="${commit_line%% *}"
      msg="${commit_line#* }"
      if $first; then first=false; else echo ","; fi
      echo "    $(jq -n \
        --arg r "$org/$repo" \
        --arg h "$hash" \
        --arg m "$msg" \
        '{repo: $r, hash: $h, message: $m}')"
    done <<< "$commits"
  done
done
echo '  ],'

# --- Open PRs with failing CI (blockers) ---
echo '  "blockers": ['
first=true
for org in "${ORGS[@]}"; do
  CLAUDE_MD="$CODE_DIR/$org/CLAUDE.md"
  [[ ! -f "$CLAUDE_MD" ]] && continue

  gh_org=$(get_gh_org "$CLAUDE_MD" "$org")
  repos=()
  while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

  for repo in "${repos[@]}"; do
    failing=$(gh pr list \
      --author "$BOT_USER" \
      --state open \
      -R "$gh_org/$repo" \
      --json number,title,url,statusCheckRollup,reviewDecision \
      2>/dev/null || echo "[]")

    if [[ "$failing" != "[]" ]] && [[ -n "$failing" ]]; then
      count=$(echo "$failing" | jq length)
      for ((j = 0; j < count; j++)); do
        pr=$(echo "$failing" | jq ".[$j]")
        has_failure=$(echo "$pr" | jq '
          (.statusCheckRollup // [] | any(.conclusion == "FAILURE"))
          or (.reviewDecision == "CHANGES_REQUESTED")
        ')
        if [[ "$has_failure" == "true" ]]; then
          if $first; then first=false; else echo ","; fi
          echo "    $(echo "$pr" | jq --arg r "$gh_org/$repo" \
            '{repo: $r, number: .number, title: .title, url: .url,
              review: .reviewDecision}')"
        fi
      done
    fi
  done
done
echo '  ]'

echo "}"
