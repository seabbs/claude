#!/usr/bin/env bash
# Tests for hooks/pr-body-guard.sh. Run: bash hooks/tests/pr-body-guard.test.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
guard="$here/../pr-body-guard.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

good=$'Opener.\n\n<details>\n<summary>Claude Opus 5.5</summary>\n\nBody.\n\n</details>'
printf '%s\n' "$good" > "$tmp/good.md"
printf 'Just a long agent essay.\n' > "$tmp/bad.md"

fails=0
# expect <allow|deny> <name> <command> [cwd]
expect() {
  local want=$1 name=$2 cmd=$3 cwd=${4:-$tmp} out got
  out="$(jq -n --arg c "$cmd" --arg d "$cwd" \
    '{tool_name: "Bash", cwd: $d, tool_input: {command: $c}}' |
    bash "$guard")"
  if printf '%s' "$out" | grep -q '"permissionDecision": *"deny"'; then
    got=deny
  else
    got=allow
  fi
  if [ "$got" = "$want" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name (want $want, got $got)"
    fails=$((fails + 1))
  fi
}

expect allow "other command" "ls -la"
expect allow "pr view" "gh pr view 3"
expect allow "body-file with details" "gh pr create --title x --body-file $tmp/good.md"
expect deny "body-file without details" "gh pr create --title x --body-file $tmp/bad.md"
expect allow "relative body-file" "gh pr create -t x -F good.md"
expect allow "quoted body-file" "gh pr create -t x --body-file \"$tmp/good.md\""
expect allow "body-file= form" "gh pr create -t x --body-file=$tmp/good.md"
expect deny "inline body without details" "gh pr create -t x --body \"Plain text\""
expect allow "inline heredoc with details" "gh pr create -t x --body \"\$(cat <<'EOF'
$good
EOF
)\""
expect deny "fill without body" "gh pr create --fill"
expect deny "no body at all" "gh pr create --title x"
expect allow "missing body-file fails open" "gh pr create -t x -F $tmp/nope.md"
expect allow "body from stdin fails open" "gh pr create -t x -F -"
expect allow "edit without body" "gh pr edit 12 --add-label bug"
expect deny "edit with bad body" "gh pr edit 12 --body-file $tmp/bad.md"
expect allow "edit with good body" "gh pr edit 12 --body-file $tmp/good.md"
expect allow "checks-passed retry" "gh pr create -t x -F $tmp/good.md # checks-passed"
expect deny "after cd" "cd /x && gh pr create -t x -F $tmp/bad.md"
expect allow "gh -R form" "gh pr create -R seabbs/x -t x -F $tmp/good.md"
expect allow "string mention only" "git commit -m \"run gh pr create later\""
expect allow "-F inside title is not a body file" \
  "gh pr create -t \"fix x-F y\" -F $tmp/good.md"
expect deny "-F inside title with bad body" \
  "gh pr create -t \"fix x-F $tmp/good.md\" -F $tmp/bad.md"
expect deny "spaced -F inside title with bad body" \
  "gh pr create -t \"fix -F $tmp/good.md\" -F $tmp/bad.md"
expect deny "spaced -F inside --title= with bad body" \
  "gh pr create --title='fix -F $tmp/good.md' -F $tmp/bad.md"
HOME=$tmp expect allow "tilde body-file" "gh pr create -t x -F ~/good.md"
HOME=$tmp expect allow "\$HOME body-file" \
  "gh pr create -t x -F \$HOME/good.md"
HOME=$tmp expect deny "\${HOME} body-file without details" \
  "gh pr create -t x -F \${HOME}/bad.md"
expect deny "short -b without details" "gh pr create -t x -b \"Plain\""
expect deny "--body= without details" "gh pr create -t x --body=\"Plain\""
expect allow "body from a file substitution" \
  "gh pr create -t x --body \"\$(cat $tmp/good.md)\""
expect allow "body from a variable" "gh pr create -t x --body \"\$BODY\""
expect deny "variable elsewhere, plain body" \
  "gh pr edit \"\$PR\" -R \"\$REPO\" --body \"Plain text\""
expect deny "heredoc body without details" "gh pr create -t x --body \"\$(cat <<'EOF'
Plain text
EOF
)\""
long="$(printf 'Evidence line %s.\n' $(seq 1 80))"
printf '%s\n' "$long" > "$tmp/long.md"
printf '## Evidence\n\nShort.\n' > "$tmp/heading.md"
expect allow "short pr comment" \
  "gh pr comment 12 --body \"CI fails on main too, see run 5.\""
expect allow "re-review request" "gh pr comment 12 -b \"@seabbs-review-bot\""
expect deny "long pr comment from file" "gh pr comment 12 --body-file $tmp/long.md"
expect deny "pr comment with a heading" "gh pr comment 12 -F $tmp/heading.md"
expect deny "long inline pr comment" "gh pr comment 12 --body \"$long\""
expect allow "pr comment from a variable" "gh pr comment 12 --body \"\$MSG\""
expect allow "issue comment is not checked" \
  "gh issue comment 12 --body-file $tmp/long.md"
expect allow "web form" "gh pr create -t x --web"
expect allow "short web form" "gh pr create -t x -w"

if [ "$fails" -ne 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
