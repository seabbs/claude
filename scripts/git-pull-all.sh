#!/usr/bin/env bash
# git-pull-all.sh — Update main branch on all local repos
# Usage: git-pull-all.sh
# Designed to run nightly before other automation
# Skips repos with uncommitted changes on main

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

CODE_DIR="${CODE_DIR:-$HOME/code}"
ORGS=(epinowcast epiforecasts EpiAware nfidd seabbs)

echo "{"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo '  "repos": ['

first=true
for org in "${ORGS[@]}"; do
  org_dir="$CODE_DIR/$org"
  [[ ! -d "$org_dir" ]] && continue

  for repo_dir in "$org_dir"/*/; do
    [[ ! -d "$repo_dir/.git" ]] && [[ ! -f "$repo_dir/.git" ]] && continue
    repo=$(basename "$repo_dir")

    # Skip worktrees (they don't have their own remote)
    if [[ -f "$repo_dir/.git" ]]; then
      # .git is a file = worktree
      continue
    fi

    status="skipped"
    reason=""
    branch=""

    # Get default branch
    default_branch=$(git -C "$repo_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
      | sed 's|refs/remotes/origin/||' || echo "main")
    branch="$default_branch"

    # Check current branch
    current=$(git -C "$repo_dir" branch --show-current 2>/dev/null || echo "")

    if [[ "$current" != "$default_branch" ]]; then
      # Not on main, check if main exists locally
      if git -C "$repo_dir" rev-parse "$default_branch" &>/dev/null; then
        # Fetch and update the tracking branch without switching
        if git -C "$repo_dir" fetch origin "$default_branch" &>/dev/null; then
          git -C "$repo_dir" branch -f "$default_branch" \
            "origin/$default_branch" &>/dev/null && \
            status="updated" || { status="failed"; reason="branch update failed"; }
        else
          status="failed"
          reason="fetch failed"
        fi
      else
        status="skipped"
        reason="no local $default_branch branch"
      fi
    else
      # On main, check for uncommitted changes
      if [[ -n $(git -C "$repo_dir" status --porcelain 2>/dev/null) ]]; then
        status="skipped"
        reason="uncommitted changes"
      else
        if git -C "$repo_dir" pull --ff-only origin "$default_branch" &>/dev/null; then
          status="updated"
        else
          status="failed"
          reason="pull failed (diverged?)"
        fi
      fi
    fi

    if $first; then first=false; else echo ","; fi
    jq -n \
      --arg repo "$org/$repo" \
      --arg branch "$branch" \
      --arg status "$status" \
      --arg reason "$reason" \
      '{repo: $repo, branch: $branch, status: $status, reason: $reason}'
  done
done

echo '  ]'
echo "}"
