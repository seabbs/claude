---
argument-hint: [rev-range]
description: Open a tmux split with diffview.nvim showing recent changes
---
Open a new tmux pane that displays the agent's recent changes using
`diffview.nvim`.

Run: `bash ~/code/seabbs/dotfiles/scripts/show-diff.sh $ARGUMENTS`

Argument behaviour:
- No argument → working tree vs HEAD (uncommitted changes only)
- A rev range such as `main...HEAD` → branch diff vs main
- Any valid rev range, e.g. `HEAD~3..HEAD` → passed through verbatim

Pick the argument based on where the changes live:
- Changes are still uncommitted → call with no argument
- Changes are committed on a feature branch → pass `main...HEAD`
- Only interested in the last N commits → pass `HEAD~N..HEAD`

Requires an active tmux session. The split opens to the right of the
current pane, running `nvim` in the repo root with `DiffviewOpen`
pre-invoked, so the user can immediately review.

After opening, let the user know the pane is up; do not try to interact
with it from this side.
