#!/usr/bin/env bash
# pr-body-guard — PreToolUse hook. Blocks `gh pr create` and `gh pr edit`
# when the PR body has no <details><summary> block, so agent-written PR text
# follows the pr-description skill (short opener, full text collapsed).
# Also blocks long or sectioned `gh pr comment` bodies: detail belongs in
# the description's dropdowns, not in comments.
#
# Heuristic: scans the command text and checks only the first gh pr call.
# Fails open when the body cannot be read.
set -u

command -v jq >/dev/null 2>&1 || exit 0
event="$(cat)"
cmd="$(printf '%s' "$event" | jq -r '.tool_input.command // empty' 2>/dev/null)"
cwd="$(printf '%s' "$event" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

# Only a gh pr create/edit at the start of a command, not a quoted mention.
nl=$'\n'
start_re="(^|[;&|(${nl}])[[:space:]]*gh[[:space:]]+pr[[:space:]]+(create|edit|comment)"
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

# A comment is conversation: a reply, a CI note, a re-review request.
COMMENT_MAX=1000
too_long() {
  [ "${#1}" -gt "$COMMENT_MAX" ] || printf '%s\n' "$1" | grep -qE '^#{1,6} '
}
comment_reason="This reads like PR description content. Put detail, \
evidence and results in the PR description, inside its <details> block \
(nested <details> for long evidence), and update it with gh pr edit \
--body-file. Keep PR comments to short conversation: replies, CI notes, \
re-review requests. Answer review findings in their threads."

judge() {
  if [ "$sub" = comment ]; then
    too_long "$1" && deny "$comment_reason"
  else
    has_details "$1" || deny "$reason"
  fi
}

reason="PR body must follow the pr-description skill: a short opener, then \
the full agent-written text inside <details><summary>MODEL</summary> ... \
</details>. Write the body to a file and pass it with --body-file, then retry."

file_re="(^|[[:space:]])(--body-file|-F)(=|[[:space:]]+)"
file_re+="(\"[^\"]*\"|'[^']*'|[^[:space:];&|]+)"
body_re="(^|[[:space:]])(--body|-b)(=|[[:space:]])"
dyn_re="(^|[[:space:]])(--body|-b)(=|[[:space:]]+)[\"']?[$]"
web_re="(^|[[:space:]])(--web|-w)([[:space:]]|$)"
title_re="(^|[[:space:]])(--title|-t)(=|[[:space:]]+)(\"[^\"]*\"|'[^']*')"

# Drop quoted titles, so flag-like text inside a title is not read as a flag.
scan="$cmd"
while [[ "$scan" =~ $title_re ]]; do
  scan="${scan/"${BASH_REMATCH[0]}"/ }"
done

if [[ "$scan" =~ $file_re ]]; then
  f="${BASH_REMATCH[4]}"
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
  judge "$(cat "$f")"
elif [[ "$scan" =~ $body_re ]]; then
  if [ "$sub" = comment ]; then
    [[ "$cmd" != *"<<"* && "$scan" =~ $dyn_re ]] && exit 0
    judge "$cmd"
    exit 0
  fi
  has_details "$cmd" && exit 0
  # A heredoc body is literal text, so judge it. A body that starts with
  # any other $ expansion (a variable or $(cat file)) is hidden, so fail open.
  [[ "$cmd" != *"<<"* && "$scan" =~ $dyn_re ]] && exit 0
  deny "$reason"
elif [ "$sub" = "create" ] && ! [[ "$scan" =~ $web_re ]]; then
  deny "$reason"
fi
exit 0
