#!/usr/bin/env bash
# org-maintenance.sh — Collect worktree and stuck PR info across an org
# Usage: org-maintenance.sh <org-name>
# Outputs JSON with worktree audit and open PR status

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

ORG="${1:?Usage: org-maintenance.sh <org-name>}"
CODE_DIR="${CODE_DIR:-$HOME/code}"
CLAUDE_MD="$CODE_DIR/$ORG/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "Error: $CLAUDE_MD not found" >&2
  exit 1
fi

gh_org=$(get_gh_org "$CLAUDE_MD" "$ORG")
repos=()
while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

echo "{"

# --- Worktree audit ---
echo '  "worktrees": ['
first=true
for repo in "${repos[@]}"; do
  repo_dir="$CODE_DIR/$ORG/$repo"
  [[ ! -d "$repo_dir/.git" ]] && [[ ! -f "$repo_dir/.git" ]] && continue

  worktree_list=$(git -C "$repo_dir" worktree list --porcelain 2>/dev/null \
    || true)
  [[ -z "$worktree_list" ]] && continue

  # Parse worktrees (skip the main one)
  wt_count=0
  prev_path=""
  prev_branch=""
  current_path=""
  current_branch=""
  while IFS= read -r wt_line; do
    if [[ "$wt_line" == "worktree "* ]]; then
      # Emit previous if it's not the first (main) worktree
      if [[ $wt_count -gt 1 ]] && [[ -n "$prev_path" ]]; then
        if $first; then first=false; else echo ","; fi
        cat <<ENTRY
    {
      "repo": "$repo",
      "path": "$prev_path",
      "branch": "$prev_branch",
      "exists": $([ -d "$prev_path" ] && echo true || echo false)
    }
ENTRY
      fi
      prev_path="$current_path"
      prev_branch="$current_branch"
      current_path="${wt_line#worktree }"
      current_branch=""
      wt_count=$((wt_count + 1))
    elif [[ "$wt_line" == "branch "* ]]; then
      current_branch="${wt_line#branch refs/heads/}"
    fi
  done <<< "$worktree_list"

  # Emit last worktree (if not the main one)
  if [[ $wt_count -gt 1 ]]; then
    if $first; then first=false; else echo ","; fi
    cat <<ENTRY
    {
      "repo": "$repo",
      "path": "$current_path",
      "branch": "$current_branch",
      "exists": $([ -d "$current_path" ] && echo true || echo false)
    }
ENTRY
  fi
done
echo '  ],'

# --- Open PRs ---
echo '  "open_prs": ['
first=true
for repo in "${repos[@]}"; do
  for author in seabbs seabbs-bot; do
    prs=$(gh pr list \
      --author "$author" \
      --state open \
      -R "$gh_org/$repo" \
      --json number,title,url,createdAt,updatedAt,mergeable,reviewDecision,statusCheckRollup \
      2>/dev/null || echo "[]")

    if [[ "$prs" != "[]" ]] && [[ -n "$prs" ]]; then
      count=$(echo "$prs" | jq length)
      for ((j = 0; j < count; j++)); do
        if $first; then first=false; else echo ","; fi
        pr_json=$(echo "$prs" | jq ".[$j]")
        echo "    $(echo "$pr_json" | jq --arg repo "$repo" \
          --arg author "$author" \
          '. + {repo: $repo, author: $author}')"
      done
    fi
  done
done
echo '  ]'

echo "}"
