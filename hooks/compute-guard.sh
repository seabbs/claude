#!/usr/bin/env bash
# compute-guard — PreToolUse hook. Holds heavy work when the machine is
# overloaded, so several Claude agents sharing one box (the archie agents hub)
# can't collectively melt it. Reads the tool event JSON on stdin; emits a deny
# decision ONLY when this call is heavy AND compute-budget reports red.
# Otherwise emits nothing (allow).
#
# Heavy = a subagent spawn (the big multiplier) or a known CPU/RAM-heavy Bash
# command (builds, compiles, package installs, pipelines, test suites). Light
# commands (git, ls, kill, edits) are never gated — including remediation like
# pkill, so an agent can always act to bring the load down.
#
# Fails OPEN everywhere: missing jq, missing budget script, parse error, etc.
# all fall through to allow, so the guard can never wedge a machine. Override a
# red verdict with COMPUTE_BUDGET_FORCE=green or ~/.cache/compute-budget-force.
set -u

dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || exit 0
command -v jq >/dev/null 2>&1 || exit 0
event="$(cat)"

tool="$(printf '%s' "$event" | jq -r '.tool_name // empty' 2>/dev/null)"

is_heavy=0
case "$tool" in
  Task|Agent)
    is_heavy=1 ;;                       # subagent fan-out — the big multiplier
  Bash)
    cmd="$(printf '%s' "$event" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    # CPU/RAM-heavy entry points. Bounded by separators so e.g. "remake" or
    # "stancheck" don't match a bare "make"/"stan".
    if printf '%s' "$cmd" | grep -Eiq \
'(^|[;&|[:space:](])(make|cmake|ninja|gcc|g\+\+|clang|cargo[[:space:]]+(build|test)|go[[:space:]]+(build|test)|R[[:space:]]+CMD[[:space:]]+(INSTALL|build|check)|Rscript|install\.packages|pak::|pkg_install|targets::tar_make|tar_make|cmdstanr|cmdstan_model|quarto[[:space:]]+render|devtools::(install|check|test|build)|pytest|tox|bazel|npm[[:space:]]+(run[[:space:]]+)?(build|test)|yarn[[:space:]]+(build|test))([[:space:]]|$|\()'; then
      is_heavy=1
    fi ;;
esac

[ "$is_heavy" -eq 1 ] || exit 0

budget="$dir/compute-budget.sh"
[ -x "$budget" ] || exit 0
# NB: compute-budget exits 1 on red (its CLI contract), which is exactly the
# case we act on — so read the verdict from the JSON, never gate on its exit.
json="$("$budget" --json 2>/dev/null)"
[ -n "$json" ] || exit 0
verdict="$(printf '%s' "$json" | jq -r '.verdict // "green"' 2>/dev/null)"
[ "$verdict" = "red" ] || exit 0

load="$(printf '%s' "$json" | jq -r '.load1 // 0' 2>/dev/null)"
ncpu="$(printf '%s' "$json" | jq -r '.ncpu // 1' 2>/dev/null)"
reason="Machine overloaded: load ${load} on ${ncpu} cores. Hold heavy/parallel work — let load fall, run builds serially, cut subagent fan-out. Recheck with hooks/compute-budget.sh. If you're sure, force through: echo green > ~/.cache/compute-budget-force"

jq -cn --arg r "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
