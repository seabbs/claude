#!/usr/bin/env bash
# org-deps.sh — Collect dependency info across repos in an org
# Usage: org-deps.sh <org-name> [org-name2 ...]
# Outputs JSON with per-repo dependency info

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: org-deps.sh <org-name> [org-name2 ...]" >&2
  exit 1
fi

CODE_DIR="${CODE_DIR:-$HOME/code}"

echo "["
first=true

for ORG in "$@"; do
  CLAUDE_MD="$CODE_DIR/$ORG/CLAUDE.md"
  if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "Warning: $CLAUDE_MD not found, skipping" >&2
    continue
  fi

  gh_org=$(get_gh_org "$CLAUDE_MD" "$ORG")

  while IFS='|' read -r repo type; do
    repo_dir="$CODE_DIR/$ORG/$repo"
    [[ ! -d "$repo_dir" ]] && continue

    if $first; then first=false; else echo ","; fi

    deps_json="{}"
    pkg_version=""

    # R package
    desc_file="$repo_dir/DESCRIPTION"
    if [[ -f "$desc_file" ]]; then
      depends=$(grep -E '^Depends:' "$desc_file" 2>/dev/null \
        | sed 's/^Depends:[[:space:]]*//' || echo "")
      imports=$(awk '/^Imports:/{found=1; sub(/^Imports:[[:space:]]*/, ""); print; next} found && /^[[:space:]]/{print; next} found{found=0}' "$desc_file" \
        | tr -d '\n' | sed 's/[[:space:]]*$//' || echo "")
      suggests=$(awk '/^Suggests:/{found=1; sub(/^Suggests:[[:space:]]*/, ""); print; next} found && /^[[:space:]]/{print; next} found{found=0}' "$desc_file" \
        | tr -d '\n' | sed 's/[[:space:]]*$//' || echo "")
      remotes=$(awk '/^Remotes:/{found=1; sub(/^Remotes:[[:space:]]*/, ""); print; next} found && /^[[:space:]]/{print; next} found{found=0}' "$desc_file" \
        | tr -d '\n' | sed 's/[[:space:]]*$//' || echo "")
      pkg_version=$(grep -E '^Version:' "$desc_file" 2>/dev/null \
        | sed 's/^Version:[[:space:]]*//' || echo "")

      deps_json=$(jq -n \
        --arg depends "$depends" \
        --arg imports "$imports" \
        --arg suggests "$suggests" \
        --arg remotes "$remotes" \
        '{depends: $depends, imports: $imports, suggests: $suggests, remotes: $remotes}')
    fi

    # Julia package
    toml_file="$repo_dir/Project.toml"
    if [[ -f "$toml_file" ]]; then
      julia_deps=$(awk '/^\[deps\]/{found=1; next} /^\[/{found=0} found{print}' "$toml_file" \
        | tr '\n' ';' || echo "")
      julia_compat=$(awk '/^\[compat\]/{found=1; next} /^\[/{found=0} found{print}' "$toml_file" \
        | tr '\n' ';' || echo "")
      if [[ -z "$pkg_version" ]]; then
        pkg_version=$(grep -E '^version' "$toml_file" 2>/dev/null \
          | head -1 | sed 's/.*=[[:space:]]*//' | tr -d '"' || echo "")
      fi

      deps_json=$(jq -n \
        --arg deps "$julia_deps" \
        --arg compat "$julia_compat" \
        '{julia_deps: $deps, julia_compat: $compat}')
    fi

    latest_tag=$(gh release list -R "$gh_org/$repo" --limit 1 \
      --json tagName --jq '.[0].tagName' 2>/dev/null || echo "")

    cat <<ENTRY
  {
    "repo": "$repo",
    "org": "$ORG",
    "gh_org": "$gh_org",
    "type": $(echo "$type" | jq -R .),
    "version": "$pkg_version",
    "latest_release_tag": "$latest_tag",
    "dependencies": $deps_json
  }
ENTRY
  done < <(parse_repo_names_with_type "$CLAUDE_MD")
done
echo "]"
