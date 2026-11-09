#!/usr/bin/env bash
# pr-body-guard — PreToolUse hook. Blocks `gh pr create` and `gh pr edit`
# when the PR body has no <details><summary> block, so agent-written PR text
# follows the pr-description skill (short opener, full text collapsed).
#
# Checks an inline --body/-b by scanning the command, and a --body-file/-F
# by reading the file. `gh pr create` with no body at all (e.g. --fill) is
# denied too. Fails OPEN when the body cannot be seen: missing jq, stdin
# body (-F -), unreadable file, or parse error.
set -u

command -v jq >/dev/null 2>&1 || exit 0
event="$(cat)"
cmd="$(printf '%s' "$event" | jq -r '.tool_input.command // empty' 2>/dev/null)"
cwd="$(printf '%s' "$event" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

# Only a gh pr create/edit at the start of a command, not a quoted mention.
nl=$'\n'
start_re="(^|[;&|(${nl}])[[:space:]]*gh[[:space:]]+pr[[:space:]]+(create|edit)"
[[ "$cmd" =~ $start_re ]] || exit 0
sub="${BASH_REMATCH[2]}"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r}}'
  exit 0
}

has_details() {
  printf '%s' "$1" | grep -qi '<details' &&
    printf '%s' "$1" | grep -qi '<summary'
}

reason="PR body must follow the pr-description skill: a short opener, then \
the full agent-written text inside <details><summary>MODEL</summary> ... \
</details>. Write the body to a file and pass it with --body-file, then retry."

file_re="(--body-file|-F)(=|[[:space:]]+)(\"[^\"]*\"|'[^']*'|[^[:space:];&|]+)"
body_re="(^|[[:space:]])(--body|-b)(=|[[:space:]])"

if [[ "$cmd" =~ $file_re ]]; then
  f="${BASH_REMATCH[3]}"
  f="${f#[\"\']}"; f="${f%[\"\']}"
  [ "$f" = "-" ] && exit 0
  # Match the literal text the agent wrote, then expand it ourselves.
  # shellcheck disable=SC2088,SC2016
  case "$f" in
    "~/"*) f="$HOME/${f#\~/}" ;;
    '$HOME/'*) f="$HOME/${f#\$HOME/}" ;;
    '${HOME}/'*) f="$HOME/${f#\$\{HOME\}/}" ;;
  esac
  [[ "$f" = /* ]] || f="${cwd:-.}/$f"
  [ -r "$f" ] || exit 0
  has_details "$(cat "$f")" || deny "$reason"
elif [[ "$cmd" =~ $body_re ]]; then
  has_details "$cmd" || deny "$reason"
elif [ "$sub" = "create" ]; then
  deny "$reason"
fi
exit 0
