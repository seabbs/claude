#!/usr/bin/env bash
# org-standards.sh — Collect config/standards info across repos in an org
# Usage: org-standards.sh <org-name>
# Outputs JSON object with:
#   - dot_github: shared config from the .github repo
#   - repos: per-repo standards presence
#   - declined: previously declined suggestions from CLAUDE.md

set -euo pipefail
source "$(dirname "$0")/_lib.sh"

ORG="${1:?Usage: org-standards.sh <org-name>}"
CODE_DIR="${CODE_DIR:-$HOME/code}"
CLAUDE_MD="$CODE_DIR/$ORG/CLAUDE.md"

if [[ ! -f "$CLAUDE_MD" ]]; then
  echo "Error: $CLAUDE_MD not found" >&2
  exit 1
fi

gh_org=$(get_gh_org "$CLAUDE_MD" "$ORG")
repos=()
while IFS= read -r r; do repos+=("$r"); done < <(parse_repo_names "$CLAUDE_MD")

# Helper: check if any of the given files exist
file_exists() {
  for f in "$@"; do
    [[ -f "$f" ]] && echo true && return
  done
  echo false
}

# ---- Section 1: .github repo shared configs ----
# Check for a .github or org-.github repo with shared workflows and configs
dot_github_dir=""
for candidate in "$CODE_DIR/$ORG/.github" \
                 "$CODE_DIR/$ORG/${ORG}-.github" \
                 "$CODE_DIR/$ORG/${gh_org}-.github"; do
  if [[ -d "$candidate/.git" ]] || [[ -f "$candidate/.git" ]]; then
    dot_github_dir="$candidate"
    break
  fi
done

dot_github_json="{}"
if [[ -n "$dot_github_dir" ]]; then
  shared_workflows="[]"
  shared_wf_dir="$dot_github_dir/workflows"
  # Also check .github/workflows within the .github repo
  [[ ! -d "$shared_wf_dir" ]] && shared_wf_dir="$dot_github_dir/.github/workflows"
  if [[ -d "$shared_wf_dir" ]]; then
    wf_names=""
    for f in "$shared_wf_dir"/*.yml "$shared_wf_dir"/*.yaml; do
      [[ -f "$f" ]] && wf_names="$wf_names$(basename "$f")"$'\n'
    done
    if [[ -n "$wf_names" ]]; then
      shared_workflows=$(echo "$wf_names" \
        | jq -R -s -c 'split("\n") | map(select(. != ""))' \
        || echo "[]")
    fi
  fi

  shared_templates="[]"
  template_dir="$dot_github_dir/.github"
  [[ ! -d "$template_dir" ]] && template_dir="$dot_github_dir"
  tmpl_names=""
  for pattern in ISSUE_TEMPLATE PULL_REQUEST_TEMPLATE.md \
                 CONTRIBUTING.md CODE_OF_CONDUCT.md STYLE_GUIDE.md \
                 FUNDING.yml SECURITY.md; do
    if [[ -e "$template_dir/$pattern" ]] || \
       [[ -e "$dot_github_dir/$pattern" ]]; then
      tmpl_names="$tmpl_names$pattern"$'\n'
    fi
  done
  if [[ -n "$tmpl_names" ]]; then
    shared_templates=$(echo "$tmpl_names" \
      | jq -R -s -c 'split("\n") | map(select(. != ""))' \
      || echo "[]")
  fi

  has_taskfile=$(file_exists "$dot_github_dir/Taskfile.yml" \
    "$dot_github_dir/Taskfile.yaml")

  dot_github_json=$(jq -n \
    --arg path "$(basename "$dot_github_dir")" \
    --argjson workflows "$shared_workflows" \
    --argjson templates "$shared_templates" \
    --argjson taskfile "$has_taskfile" \
    '{path: $path, shared_workflows: $workflows, shared_templates: $templates, has_taskfile: $taskfile}')
fi

# ---- Section 2: Declined suggestions ----
# Parse "## Declined standards" section from CLAUDE.md
declined_json="[]"
if grep -q "## Declined standards" "$CLAUDE_MD" 2>/dev/null; then
  declined_lines=""
  in_declined=false
  while IFS= read -r line; do
    if [[ "$line" == *"## Declined standards"* ]]; then
      in_declined=true
      continue
    fi
    if $in_declined && [[ "$line" == "## "* ]]; then
      break
    fi
    if $in_declined && [[ "$line" == "- "* ]] || \
       ($in_declined && [[ "$line" == "| "* ]]); then
      declined_lines="$declined_lines$line"$'\n'
    fi
  done < "$CLAUDE_MD"
  if [[ -n "$declined_lines" ]]; then
    declined_json=$(echo "$declined_lines" \
      | jq -R -s -c 'split("\n") | map(select(. != ""))' \
      || echo "[]")
  fi
fi

# ---- Section 3: Open standards PRs ----
# Check for open PRs from bot with standards-related titles
open_prs="[]"
if command -v gh &>/dev/null; then
  open_prs=$(gh pr list -R "$gh_org/.github" \
    --author "@me" --state open \
    --json number,title,url 2>/dev/null \
    || echo "[]")
  [[ -z "$open_prs" ]] && open_prs="[]"
fi

# ---- Section 4: Per-repo config ----
echo "{"
echo "  \"org\": \"$ORG\","
echo "  \"gh_org\": \"$gh_org\","
echo "  \"dot_github\": $dot_github_json,"
echo "  \"declined\": $declined_json,"
echo "  \"open_standards_prs\": $open_prs,"
echo "  \"repos\": ["

first=true
for repo in "${repos[@]}"; do
  repo_dir="$CODE_DIR/$ORG/$repo"
  [[ ! -d "$repo_dir" ]] && continue

  if $first; then first=false; else echo ","; fi

  # Check for standard config files
  has_lintr=$(file_exists "$repo_dir/.lintr")
  has_precommit=$(file_exists "$repo_dir/.pre-commit-config.yaml")
  has_citation=$(file_exists "$repo_dir/CITATION.cff")
  has_claude=$(file_exists "$repo_dir/CLAUDE.md")
  has_license=$(file_exists "$repo_dir/LICENSE" "$repo_dir/LICENSE.md")
  has_readme=$(file_exists "$repo_dir/README.md" "$repo_dir/README.Rmd")
  has_news=$(file_exists "$repo_dir/NEWS.md" "$repo_dir/CHANGELOG.md")
  has_gitignore=$(file_exists "$repo_dir/.gitignore")
  has_taskfile=$(file_exists "$repo_dir/Taskfile.yml" \
    "$repo_dir/Taskfile.yaml")

  # Check for CI workflows
  has_ci=false
  ci_files="[]"
  workflow_dir="$repo_dir/.github/workflows"
  if [[ -d "$workflow_dir" ]]; then
    has_ci=true
    wf_names=""
    for f in "$workflow_dir"/*.yml "$workflow_dir"/*.yaml; do
      [[ -f "$f" ]] && wf_names="$wf_names$(basename "$f")"$'\n'
    done
    if [[ -n "$wf_names" ]]; then
      ci_files=$(echo "$wf_names" \
        | jq -R -s -c 'split("\n") | map(select(. != ""))' \
        || echo "[]")
    fi
  fi

  # Check which shared workflows are referenced locally
  uses_shared="[]"
  if [[ -d "$workflow_dir" ]]; then
    shared_refs=""
    for f in "$workflow_dir"/*.yml "$workflow_dir"/*.yaml; do
      [[ ! -f "$f" ]] && continue
      refs=$(grep -h "uses:.*${gh_org}/\\.github" "$f" 2>/dev/null \
        || true)
      if [[ -n "$refs" ]]; then
        shared_refs="$shared_refs$refs"$'\n'
      fi
    done
    if [[ -n "$shared_refs" ]]; then
      uses_shared=$(echo "$shared_refs" \
        | sed 's/.*uses: *//' | sort -u \
        | jq -R -s -c 'split("\n") | map(select(. != ""))' \
        || echo "[]")
    fi
  fi

  # Check for package-specific configs
  has_description=$(file_exists "$repo_dir/DESCRIPTION")
  has_project_toml=$(file_exists "$repo_dir/Project.toml")
  has_pkgdown=$(file_exists "$repo_dir/_pkgdown.yml" \
    "$repo_dir/pkgdown/_pkgdown.yml")
  has_julia_formatter=$(file_exists "$repo_dir/.JuliaFormatter.toml")

  # Get README badges count
  badge_count=0
  if [[ -f "$repo_dir/README.md" ]]; then
    badge_count=$(head -30 "$repo_dir/README.md" \
      | grep -c '\[!\[' || true)
    [[ -z "$badge_count" ]] && badge_count=0
  fi

  cat <<ENTRY
  {
    "repo": "$repo",
    "gh_org": "$gh_org",
    "config": {
      "lintr": $has_lintr,
      "pre_commit": $has_precommit,
      "citation": $has_citation,
      "claude_md": $has_claude,
      "license": $has_license,
      "readme": $has_readme,
      "news": $has_news,
      "gitignore": $has_gitignore,
      "ci": $has_ci,
      "ci_files": $ci_files,
      "uses_shared_workflows": $uses_shared,
      "taskfile": $has_taskfile,
      "description": $has_description,
      "project_toml": $has_project_toml,
      "pkgdown": $has_pkgdown,
      "julia_formatter": $has_julia_formatter,
      "badge_count": $badge_count
    }
  }
ENTRY
done
echo "  ]"
echo "}"
