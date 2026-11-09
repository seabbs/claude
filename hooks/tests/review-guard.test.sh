#!/usr/bin/env bash
# Tests for hooks/review-guard.sh. Run: bash hooks/tests/review-guard.test.sh
# Stubs gh on PATH and uses a throwaway git repo for the branch.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
guard="$here/../review-guard.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/repo"
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "pr view") [ -n "${RG_PR:-}" ] || exit 1; printf '%s' "$RG_PR" ;;
  "api graphql") printf '%s' "$RG_GQL" ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/gh"
git -C "$tmp/repo" init -q -b main
git -C "$tmp/repo" -c user.name=t -c user.email=t@t commit -q \
  --allow-empty -m init
git -C "$tmp/repo" switch -q -c feat/x

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
old="2020-01-01T00:00:00Z"
pr() { # pr <author> <created> [draft] [label]
  jq -nc --arg a "$1" --arg c "$2" --argjson d "${3:-false}" \
    --arg l "${4:-}" '{number: 7, state: "OPEN", isDraft: $d,
    url: "https://github.com/seabbs/x/pull/7", headRefOid: "abc",
    createdAt: $c, author: {login: $a},
    labels: (if $l == "" then [] else [{name: $l}] end)}'
}
thread() { # thread <resolved> <last-author>
  jq -nc --argjson r "$1" --arg l "$2" '{isResolved: $r, comments: {nodes: [
    {author: {login: "seabbs-review-bot"}, url: "https://x/t1"},
    {author: {login: $l}, url: "https://x/t2"}]}}'
}
gql() { # gql <reviewed> [thread...]
  local r=$1; shift
  jq -nc --argjson r "$r" --argjson t "$(printf '%s\n' "$@" | jq -sc .)" \
    '{data: {repository: {pullRequest: {
      reviews: {nodes: (if $r then [{author: {login: "seabbs-review-bot"}}]
                        else [] end)},
      reviewThreads: {nodes: $t}}}}}'
}

fails=0
# expect <allow|block> <name> [cwd]
expect() {
  local want=$1 name=$2 cwd=${3:-$tmp/repo} out got
  out="$(jq -nc --arg d "$cwd" '{cwd: $d, stop_hook_active: false}' |
    PATH="$tmp/bin:$PATH" XDG_CACHE_HOME="$tmp/cache" bash "$guard")"
  if printf '%s' "$out" | grep -q '"decision": *"block"'; then
    got=block
  else
    got=allow
  fi
  if [ "$got" = "$want" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name (want $want, got $got): $out"
    fails=$((fails + 1))
  fi
}

answered="$(thread false seabbs-bot)"
open="$(thread false seabbs)"
resolved="$(thread true seabbs)"

RG_PR="" RG_GQL="" expect allow "no PR for branch"
expect allow "not a git repo" "$tmp/bin"
RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql true "$answered")" \
  expect allow "every thread answered"
RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql true "$resolved")" \
  expect allow "resolved thread"
RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql true "$open" "$answered")" \
  expect block "unanswered thread"
RG_PR="$(pr someone "$old")" RG_GQL="$(gql true "$open")" \
  expect allow "someone else's PR"
RG_PR="$(pr seabbs "$old" false no-review)" RG_GQL="$(gql true "$open")" \
  expect allow "opted out with no-review"
RG_PR="$(pr seabbs-bot "$now")" RG_GQL="$(gql false)" \
  expect block "new PR still waiting for its review"
RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql false)" \
  expect allow "old PR never reviewed"
RG_PR="$(pr seabbs-bot "$now" true)" RG_GQL="$(gql false)" \
  expect allow "draft is not reviewed automatically"

# The block count is per PR head, so a stuck agent is let go eventually.
rm -rf "$tmp/cache"
for i in 1 2 3; do
  RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql true "$open")" \
    expect block "unanswered, block $i"
done
RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql true "$open")" \
  expect allow "unanswered, gives up after 3 blocks"
git -C "$tmp/repo" switch -q main
RG_PR="$(pr seabbs-bot "$old")" RG_GQL="$(gql true "$open")" \
  expect allow "on the default branch"

if [ "$fails" -ne 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
