#!/usr/bin/env bash
# bot-tasks.sh — Collect unprocessed bot task requests
# Usage: bot-tasks.sh
# Fetches bot notifications where owner has requested action
# Outputs JSON object of task requests with context
# Uses emoji reaction (eyes) to mark processed requests
#
# Bot/owner accounts are read from the first org's CLAUDE.md
# automation config, or from env vars BOT_USER/OWNER_USER.

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

CODE_DIR="${CODE_DIR:-$HOME/code}"

# Read accounts from first available org config
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

REACT_EMOJI="eyes"

echo "{"

# --- Unread notifications ---
echo '  "notifications": '
notifications=$(gh api notifications \
  --jq '[.[] | select(.reason == "mention" or .reason == "comment" or .reason == "subscribed")]' \
  2>/dev/null || echo "[]")
echo "  $notifications,"

# --- Extract task-like notifications with context ---
echo '  "tasks": ['
first=true
count=$(echo "$notifications" | jq length)
for ((i = 0; i < count; i++)); do
  notif=$(echo "$notifications" | jq ".[$i]")
  thread_id=$(echo "$notif" | jq -r '.id')
  subject_type=$(echo "$notif" | jq -r '.subject.type')
  subject_url=$(echo "$notif" | jq -r '.subject.url')
  repo_full=$(echo "$notif" | jq -r '.repository.full_name')

  # Only handle issues and PRs
  [[ "$subject_type" != "Issue" ]] && \
    [[ "$subject_type" != "PullRequest" ]] && continue

  # Fetch the issue/PR details
  item=$(gh api "$subject_url" 2>/dev/null || echo "{}")
  [[ "$item" == "{}" ]] && continue

  item_number=$(echo "$item" | jq -r '.number')

  # Fetch comments, look for seabbs requests
  comments_url=$(echo "$item" | jq -r '.comments_url // empty')
  [[ -z "$comments_url" ]] && continue

  comments=$(gh api "$comments_url" \
    --jq '[.[] | select(.user.login == "'"$OWNER_USER"'") | {id: .id, body: .body, created_at: .created_at}]' \
    2>/dev/null || echo "[]")

  # Check each seabbs comment for task patterns
  comment_count=$(echo "$comments" | jq length)
  for ((c = 0; c < comment_count; c++)); do
    comment=$(echo "$comments" | jq ".[$c]")
    comment_id=$(echo "$comment" | jq -r '.id')
    body=$(echo "$comment" | jq -r '.body')

    # Check if this comment has the eyes reaction (already processed)
    reactions=$(gh api "repos/$repo_full/issues/comments/$comment_id/reactions" \
      --jq "[.[] | select(.user.login == \"'"$BOT_USER"'\" and .content == \"$REACT_EMOJI\")] | length" \
      2>/dev/null || echo 0)
    [[ "$reactions" -gt 0 ]] && continue

    # Check if comment mentions bot or looks like a task request
    is_task=false
    if echo "$body" | grep -qi '@$BOT_USER'; then
      is_task=true
    elif echo "$body" | grep -qi 'can you\|please\|could you\|fix\|update\|add\|do this\|implement'; then
      is_task=true
    fi

    if $is_task; then
      if $first; then first=false; else echo ","; fi
      jq -n \
        --arg thread_id "$thread_id" \
        --arg repo "$repo_full" \
        --arg type "$subject_type" \
        --argjson number "$item_number" \
        --arg comment_id "$comment_id" \
        --arg body "$body" \
        --arg url "$(echo "$item" | jq -r '.html_url')" \
        --arg title "$(echo "$item" | jq -r '.title')" \
        '{
          thread_id: $thread_id,
          repo: $repo,
          type: $type,
          number: $number,
          title: $title,
          url: $url,
          comment_id: $comment_id,
          request: $body
        }'
    fi
  done
done
echo '  ]'

echo "}"
