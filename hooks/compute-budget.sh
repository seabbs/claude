#!/usr/bin/env bash
# compute-budget — does this machine have headroom to spin up heavy work
# (subagents, source builds, test suites)?
#
# It exists because several independent Claude agents can share one box (the
# archie agents hub) with no view of each other. The load average is the one
# signal they all see, so gating heavy work on it coordinates them without any
# shared state: when the box fills up, every agent reads the same red light.
#
# Cross-platform (Linux + macOS). On the dedicated Mac it almost never trips
# (many cores, low load); on a loaded shared box it does. So the same check is
# safe to ship in the shared config.
#
# Usage:
#   compute-budget          human summary on stderr, verdict word on stdout
#   compute-budget --json   one-line JSON (for the PreToolUse hook)
#   compute-budget --max    recommended max concurrent heavy tasks only
#
# Exit status: 0 = ok to proceed (green/amber), 1 = red (hold / serialise).
# Fails OPEN: if anything cannot be read, it reports green and exits 0 so the
# guard can never wedge a machine by mistake.
#
# Override (escape hatch): set verdict to green|amber|red via either the env var
# COMPUTE_BUDGET_FORCE, or a sentinel file ~/.cache/compute-budget-force holding
# the word. The file works mid-session and an agent can set it via Bash, e.g.
#   echo green > ~/.cache/compute-budget-force   # force work through
#   rm ~/.cache/compute-budget-force             # restore real check

set -u

ncpu=1
load1=0
swap_used_pct=0
mem_avail_pct=100

if [ -r /proc/loadavg ]; then
  # Linux
  ncpu=$(nproc 2>/dev/null || echo 1)
  load1=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo 0)
  if [ -r /proc/meminfo ]; then
    memtot=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    memav=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    swtot=$(awk '/^SwapTotal:/{print $2}' /proc/meminfo)
    swfree=$(awk '/^SwapFree:/{print $2}' /proc/meminfo)
    [ "${memtot:-0}" -gt 0 ] 2>/dev/null \
      && mem_avail_pct=$(( 100 * ${memav:-0} / memtot ))
    [ "${swtot:-0}" -gt 0 ] 2>/dev/null \
      && swap_used_pct=$(( 100 * (swtot - ${swfree:-0}) / swtot ))
  fi
elif command -v sysctl >/dev/null 2>&1; then
  # macOS (and other BSD): load from sysctl, skip swap/mem (managed differently)
  ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
  load1=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
fi

[ -n "${ncpu:-}" ] && [ "$ncpu" -ge 1 ] 2>/dev/null || ncpu=1
[ -n "${load1:-}" ] || load1=0

# Derive verdict + recommended concurrency in one awk pass (float-safe).
# red    : load >= ncpu (fully oversubscribed) OR swap thrashing on Linux
# amber  : load >= 0.7 * ncpu
# green  : otherwise
# maxpar : cores left after current load, minus a one-core safety margin
read -r verdict maxpar < <(
  awk -v n="$ncpu" -v l="$load1" -v sw="$swap_used_pct" -v ma="$mem_avail_pct" '
    BEGIN {
      ratio = l / n
      mp = int(n - l - 1); if (mp < 0) mp = 0
      red = (ratio >= 1.0) || (sw >= 50 && ma <= 10)
      amber = (ratio >= 0.7)
      v = red ? "red" : (amber ? "amber" : "green")
      print v, mp
    }')

# Manual override / test hook: COMPUTE_BUDGET_FORCE or the sentinel file pins the
# verdict (e.g. to test the gate, or to force work through on a box you know is
# fine). max_parallel follows for red so callers still back off.
force="${COMPUTE_BUDGET_FORCE:-}"
if [ -z "$force" ] && [ -r "$HOME/.cache/compute-budget-force" ]; then
  force=$(tr -d '[:space:]' < "$HOME/.cache/compute-budget-force" 2>/dev/null)
fi
case "$force" in
  green|amber) verdict="$force" ;;
  red)         verdict=red; maxpar=0 ;;
esac

summary=$(printf 'load %.2f / %s cores  swap_used %s%%  mem_avail %s%%  -> %s (max_parallel %s)' \
  "$load1" "$ncpu" "$swap_used_pct" "$mem_avail_pct" "$verdict" "$maxpar")

case "${1:-}" in
  --json)
    printf '{"verdict":"%s","load1":%s,"ncpu":%s,"swap_used_pct":%s,"mem_avail_pct":%s,"max_parallel":%s}\n' \
      "$verdict" "$load1" "$ncpu" "$swap_used_pct" "$mem_avail_pct" "$maxpar"
    ;;
  --max)
    printf '%s\n' "$maxpar"
    ;;
  *)
    printf '%s\n' "$summary" >&2
    printf '%s\n' "$verdict"
    ;;
esac

[ "$verdict" = "red" ] && exit 1
exit 0
