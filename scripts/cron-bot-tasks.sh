#!/usr/bin/env bash
# cron-bot-tasks.sh — Poll for new bot task requests, trigger if needed
# Usage: cron-bot-tasks.sh
# Designed to run from cron every 15 minutes
# Only triggers Claude Code if there are new unprocessed requests
#
# Cron entry (add with: crontab -e):
#   */15 7-22 * * 0-5 ~/.claude/scripts/cron-bot-tasks.sh >> ~/.claude/logs/cron-bot-tasks.log 2>&1
#
# The script is idempotent — safe to run multiple times.
# Uses a lock file to prevent concurrent runs.
# Uses emoji reactions (eyes 👀) to track which requests have been seen.

set -euo pipefail

LOCK_FILE="${HOME}/.claude/locks/cron-bot-tasks.lock"
LOG_DIR="${HOME}/.claude/logs"
REACT_EMOJI="eyes"

# Ensure directories exist
mkdir -p "$(dirname "$LOCK_FILE")" "$LOG_DIR"

# Lock file to prevent concurrent runs
cleanup() { rm -f "$LOCK_FILE"; }
trap cleanup EXIT

if [[ -f "$LOCK_FILE" ]]; then
  # Check if the lock is stale (older than 30 minutes)
  if [[ "$(uname)" == "Darwin" ]]; then
    lock_age=$(( $(date +%s) - $(stat -f%m "$LOCK_FILE") ))
  else
    lock_age=$(( $(date +%s) - $(stat -c%Y "$LOCK_FILE") ))
  fi
  if [[ $lock_age -gt 1800 ]]; then
    echo "[$(date)] Stale lock file (${lock_age}s old), removing"
    rm -f "$LOCK_FILE"
  else
    echo "[$(date)] Another instance is running (lock age: ${lock_age}s), skipping"
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"

echo "[$(date)] Checking for new bot task requests..."

# Quick check: any unread notifications mentioning bot?
notif_count=$(gh api notifications \
  --jq '[.[] | select(.reason == "mention" or .reason == "comment")] | length' \
  2>/dev/null || echo 0)

if [[ "$notif_count" -eq 0 ]]; then
  echo "[$(date)] No relevant notifications, nothing to do"
  exit 0
fi

echo "[$(date)] Found $notif_count notifications, checking for unprocessed tasks..."

# Run the bot-tasks script to find actual unprocessed requests
SCRIPT_DIR="$(dirname "$0")"
tasks_json=$("$SCRIPT_DIR/bot-tasks.sh" 2>/dev/null || echo '{"tasks":[]}')
task_count=$(echo "$tasks_json" | jq '.tasks | length' 2>/dev/null || echo 0)

if [[ "$task_count" -eq 0 ]]; then
  echo "[$(date)] No unprocessed task requests found"
  exit 0
fi

echo "[$(date)] Found $task_count unprocessed task(s), triggering Claude Code..."

# Write the tasks to a temp file for Claude to read
TASK_FILE="$LOG_DIR/pending-bot-tasks.json"
echo "$tasks_json" > "$TASK_FILE"

# Automated tasks always use claude (not happy)
CLAUDE_CMD=""
if command -v claude &>/dev/null; then
  CLAUDE_CMD="claude"
else
  echo "[$(date)] ERROR: 'claude' not found in PATH"
  exit 1
fi

# Allowed tools (safer than --dangerously-skip-permissions)
ALLOWED_TOOLS="Bash,Read,Edit,Write,Glob,Grep"

echo "[$(date)] Running: $CLAUDE_CMD /bot-tasks --all"
$CLAUDE_CMD --print \
  --allowedTools "$ALLOWED_TOOLS" \
  --prompt "/bot-tasks --all" \
  >> "$LOG_DIR/cron-bot-tasks-run.log" 2>&1 \
  || echo "[$(date)] Claude Code exited with code $?"

echo "[$(date)] Bot tasks run complete"
