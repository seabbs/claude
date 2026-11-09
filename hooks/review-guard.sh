#!/usr/bin/env bash
# Stop hook: keep an agent session going while the PR for its branch has
# seabbs-review-bot findings nobody has answered, or is new and still
# waiting for its first review. Blocks at most MAX times per PR head, so a
# stuck agent is let go. Fails open on any error.
set -u

BOT="seabbs-review-bot"
AGENT="seabbs-bot"
OWNERS=" seabbs seabbs-bot "
SKIP_LABEL="no-review"
MAX="${REVIEW_GUARD_MAX:-3}"
PENDING_SECS=1800

# macOS has no timeout(1) unless coreutils is installed.
t() { if command -v timeout >/dev/null; then timeout 15 "$@"; else "$@"; fi; }

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<< "$input" 2>/dev/null)"
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0
cd "$cwd" 2>/dev/null || exit 0

branch="$(git branch --show-current 2>/dev/null)" || exit 0
default="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"
case "$branch" in
  "" | main | master | "${default#origin/}") exit 0 ;;
esac

pr="$(t gh pr view --json \
  number,state,isDraft,url,headRefOid,createdAt,author,labels \
  2>/dev/null)" || exit 0
[ "$(jq -r .state <<< "$pr")" = OPEN ] || exit 0
case "$OWNERS" in
  *" $(jq -r .author.login <<< "$pr") "*) ;;
  *) exit 0 ;;
esac
jq -e --arg l "$SKIP_LABEL" 'any(.labels[]; .name == $l)' \
  <<< "$pr" >/dev/null && exit 0

url="$(jq -r .url <<< "$pr")"
slug="${url#https://github.com/}"
owner="${slug%%/*}"
rest="${slug#*/}"
name="${rest%%/*}"
# shellcheck disable=SC2016  # GraphQL variables, not shell
query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){
pullRequest(number:$n){reviews(last:100){nodes{author{login}}}
reviewThreads(first:100){nodes{isResolved comments(first:100){nodes{
author{login} url}}}}}}}'
state="$(t gh api graphql -f query="$query" -f o="$owner" \
  -f r="$name" -F n="$(jq -r .number <<< "$pr")" 2>/dev/null)" || exit 0

# A finding counts as handled once resolved or seabbs-bot has the last word.
verdict="$(jq -r --arg bot "$BOT" --arg agent "$AGENT" \
  --argjson pr "$pr" --argjson secs "$PENDING_SECS" '
  .data.repository.pullRequest as $p
  | [$p.reviewThreads.nodes[]
     | select(.comments.nodes[0].author.login == $bot)
     | select((.isResolved or .comments.nodes[-1].author.login == $agent)
              | not)
     | .comments.nodes[0].url] as $open
  | if ($open | length) > 0 then
      "unanswered\n" + ($open | map("- " + .) | join("\n"))
    elif (any($p.reviews.nodes[]; .author.login == $bot) | not)
         and ($pr.isDraft | not)
         and (now - ($pr.createdAt | fromdateiso8601)) < $secs then
      "pending"
    else "ok" end' <<< "$state" 2>/dev/null)" || exit 0
[ "${verdict%%$'\n'*}" = ok ] && exit 0

# Count blocks per PR head so an agent that cannot finish is let go.
dir="${XDG_CACHE_HOME:-$HOME/.cache}/review-guard"
mkdir -p "$dir" 2>/dev/null || exit 0
key="$dir/${owner}_${name}_$(jq -r '"\(.number)_\(.headRefOid)"' <<< "$pr")"
count=$(( $(cat "$key" 2>/dev/null || echo 0) + 1 ))
[ "$count" -le "$MAX" ] || exit 0
echo "$count" > "$key"

if [ "$verdict" = pending ]; then
  reason="$url is waiting for its first seabbs-review-bot review, which \
usually lands within ten minutes. Wait for it (poll every few minutes, \
e.g. with Monitor), then answer each finding as CLAUDE.md says."
else
  reason="$url has seabbs-review-bot findings with no answer. In each \
thread, fix it and reply with the commit, or reply saying why not. Put \
anything that needs seabbs on the 'Needs your decision:' line of the PR \
description. Unanswered threads:
${verdict#*$'\n'}"
fi
jq -n --arg r "$reason (review-guard block $count of $MAX)" \
  '{decision: "block", reason: $r}'
