#!/usr/bin/env bash
# org-releases.sh — Check release status of packages in an org
# Usage: org-releases.sh <org-name>
# Outputs JSON array of per-package release info

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

ORG="${1:?Usage: org-releases.sh <org-name>}"
CODE_DIR="${CODE_DIR:-$HOME/code}"
CLAUDE_MD="$CODE_DIR/$ORG/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "Error: $CLAUDE_MD not found" >&2
  exit 1
fi

gh_org=$(get_gh_org "$CLAUDE_MD" "$ORG")

# Only include packages
repos=()
types=()
while IFS='|' read -r name type; do
  if [[ "$type" == *"package"* ]]; then
    repos+=("$name")
    types+=("$type")
  fi
done < <(parse_repo_names_with_type "$CLAUDE_MD")

echo "["
first=true
for i in "${!repos[@]}"; do
  repo="${repos[$i]}"
  type="${types[$i]}"
  repo_dir="$CODE_DIR/$ORG/$repo"

  if $first; then first=false; else echo ","; fi

  [[ ! -d "$repo_dir" ]] && {
    echo "  {\"repo\": \"$repo\", \"error\": \"directory not found\"}"
    continue
  }

  # Get latest release
  release_json=$(gh release list -R "$gh_org/$repo" --limit 1 \
    --json tagName,publishedAt,name 2>/dev/null || echo "[]")
  latest_tag=$(echo "$release_json" | jq -r '.[0].tagName // ""')
  release_date=$(echo "$release_json" | jq -r '.[0].publishedAt // ""')

  # Count commits since tag
  commits_since=0
  if [[ -n "$latest_tag" ]] && \
     git -C "$repo_dir" rev-parse "$latest_tag" &>/dev/null; then
    commits_since=$(git -C "$repo_dir" rev-list \
      "$latest_tag"..HEAD --count 2>/dev/null || echo 0)
  fi

  # Get current version from DESCRIPTION or Project.toml
  pkg_version=""
  if [[ -f "$repo_dir/DESCRIPTION" ]]; then
    pkg_version=$(grep -E '^Version:' "$repo_dir/DESCRIPTION" \
      | sed 's/^Version:[[:space:]]*//' || echo "")
  elif [[ -f "$repo_dir/Project.toml" ]]; then
    pkg_version=$(grep -E '^version' "$repo_dir/Project.toml" \
      | head -1 | sed 's/.*=[[:space:]]*//' | tr -d '"' || echo "")
  fi

  # Check NEWS.md or CHANGELOG.md for unreleased section
  has_unreleased=false
  for news_file in NEWS.md CHANGELOG.md NEWS; do
    if [[ -f "$repo_dir/$news_file" ]]; then
      if head -20 "$repo_dir/$news_file" \
         | grep -iq 'development\|unreleased\|dev'; then
        has_unreleased=true
      fi
      break
    fi
  done

  # Check main CI status
  ci_status=$(gh run list -R "$gh_org/$repo" \
    --branch main --limit 1 \
    --json conclusion --jq '.[0].conclusion' \
    2>/dev/null || echo "unknown")

  cat <<ENTRY
  {
    "repo": "$repo",
    "type": $(echo "$type" | jq -R .),
    "gh_org": "$gh_org",
    "version": "$pkg_version",
    "latest_tag": "$latest_tag",
    "release_date": "$release_date",
    "commits_since_release": $commits_since,
    "has_unreleased_news": $has_unreleased,
    "main_ci": "$ci_status"
  }
ENTRY
done
echo "]"
