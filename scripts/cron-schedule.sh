#!/usr/bin/env bash
# cron-schedule.sh — Nightly automation runner
# Usage: cron-schedule.sh
# Runs the full org automation suite in order with gaps
# Designed for cron: 0 1 * * 0-4 cron-schedule.sh
#
# Schedule (all times local):
#   01:00 — git-pull-all (update all repos)
#   01:10 — org-maintenance (per org, sonnet)
#   01:40 — org-ci-health (per org, sonnet)
#   02:10 — org-standards (per org, opus)
#   02:40 — org-deps (all orgs at once, opus)
#   03:00 — org-issues-tidy (per org, sonnet)
#   03:30 — org-issues-do (per org, opus)
#   04:00 — org-releases (per org, opus)
#   04:30 — bot-tasks (all, opus)
#
# Only runs Sun-Thu nights. Skips Fri-Sat.
# The bot-tasks poll (cron-bot-tasks.sh) runs separately.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${HOME}/.claude/logs"
CODE_DIR="${CODE_DIR:-$HOME/code}"
LOCK_FILE="${HOME}/.claude/locks/cron-schedule.lock"

# Org list (configurable via env)
ORGS="${CRON_ORGS:-epinowcast epiforecasts EpiAware}"

# Weekend guard: skip Fri/Sat nights (date +%u: 5=Fri, 6=Sat)
day_of_week=$(date +%u)
if [[ $day_of_week -eq 5 || $day_of_week -eq 6 ]]; then
  if [[ "${FORCE_WEEKEND:-}" != "true" ]]; then
    echo "[$(date)] Weekend — skipping nightly run"
    exit 0
  fi
fi

# Use claude CLI for automated tasks (not happy)
CLAUDE_CMD=""
if command -v claude &>/dev/null; then
  CLAUDE_CMD="claude"
else
  echo "[$(date)] ERROR: 'claude' not found" >&2
  exit 1
fi

# Model IDs
SONNET="claude-sonnet-4-5-20250929"
# Opus is default (no --model flag needed)

# Allowed tools for unattended runs
ALLOWED_TOOLS="Bash,Read,Edit,Write,Glob,Grep"

mkdir -p "$LOG_DIR" "$(dirname "$LOCK_FILE")"

# Lock
cleanup() { rm -f "$LOCK_FILE"; }
trap cleanup EXIT

if [[ -f "$LOCK_FILE" ]]; then
  lock_age=$(( $(date +%s) - $(stat -c%Y "$LOCK_FILE" \
    2>/dev/null || stat -f%m "$LOCK_FILE") ))
  if [[ $lock_age -gt 14400 ]]; then  # 4 hours
    echo "[$(date)] Stale lock (${lock_age}s), removing"
    rm -f "$LOCK_FILE"
  else
    echo "[$(date)] Schedule already running (${lock_age}s)"
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"

run_skill() {
  local skill="$1"
  local log_name="$2"
  local model="${3:-}"
  local log_file
  log_file="$LOG_DIR/cron-${log_name}-$(date +%Y%m%d).log"
  local model_flag=""
  [[ -n "$model" ]] && model_flag="--model $model"

  echo "[$(date)] Running: $skill (${model:-opus})"
  $CLAUDE_CMD --print \
    $model_flag \
    --allowedTools "$ALLOWED_TOOLS" \
    --prompt "$skill" \
    >> "$log_file" 2>&1 \
    || echo "[$(date)] $skill exited with code $?"
  echo "[$(date)] Finished: $skill"
}

run_script() {
  local script="$1"
  local log_name="$2"
  local log_file
  log_file="$LOG_DIR/cron-${log_name}-$(date +%Y%m%d).log"

  echo "[$(date)] Running script: $script"
  "$SCRIPT_DIR/$script" >> "$log_file" 2>&1 \
    || echo "[$(date)] $script exited with code $?"
  echo "[$(date)] Finished script: $script"
}

gap() {
  local mins="${1:-10}"
  echo "[$(date)] Waiting ${mins}m..."
  sleep $((mins * 60))
}

# ===== NIGHTLY SEQUENCE =====

echo "[$(date)] === Nightly automation starting ==="

# 1. Update all repos
run_script "git-pull-all.sh" "git-pull"
gap 10

# 2. Maintenance per org (sonnet — simple cleanup)
for org in $ORGS; do
  run_skill "/org-maintenance $org" \
    "maintenance-$org" "$SONNET"
  gap 5
done
gap 10

# 3. CI health per org (sonnet — status checking)
for org in $ORGS; do
  run_skill "/org-ci-health $org" \
    "ci-health-$org" "$SONNET"
  gap 5
done
gap 10

# 4. Standards per org (opus — code changes, PRs)
for org in $ORGS; do
  run_skill "/org-standards $org" "standards-$org"
  gap 5
done
gap 10

# 5. Dependencies (opus — cross-repo reasoning)
run_skill "/org-deps $ORGS" "deps"
gap 10

# 6. Issues tidy per org (sonnet — commenting)
for org in $ORGS; do
  run_skill "/org-issues-tidy $org" \
    "issues-tidy-$org" "$SONNET"
  gap 5
done
gap 10

# 7. Issues do per org (opus — code changes)
for org in $ORGS; do
  run_skill "/org-issues-do $org 3" "issues-do-$org"
  gap 5
done
gap 10

# 8. Releases per org (opus — release prep)
for org in $ORGS; do
  run_skill "/org-releases $org" "releases-$org"
  gap 5
done
gap 10

# 9. Bot tasks (opus — complex task execution)
run_skill "/bot-tasks --all" "bot-tasks"

echo "[$(date)] === Nightly automation complete ==="
