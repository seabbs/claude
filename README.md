# Claude Code Configuration

Personal Claude Code configuration for Sam Abbott (@seabbs).

## Architecture

Config lives here; skills live in the
[`seabbs/skills`](https://github.com/seabbs/skills) marketplace.

- **CLAUDE.md** -- global preferences, coding standards, skill dispatch rules
- **commands/** -- 9 short slash commands (<20 lines each)
- **scripts/** -- 15 helper scripts for org automation
- **settings.json** -- model, status line, enabled plugins
- **settings.local.json** -- permissions and sandbox config
- **setup.sh** -- registers marketplace and installs plugins

Skills are installed via the plugin system from the marketplace,
not tracked in this repo.

## Setup

This repo is added as a submodule at `dotfiles/claude/`.
Symlinks are created by `dotfiles/scripts/link.sh`.

```bash
# After cloning dotfiles and running link.sh:
~/.claude/setup.sh
```

## Commands

| Command | Description |
|---|---|
| `/academic-revise` | Revise academic text from reviewer comments |
| `/check-requirements` | Verify work against original requirements |
| `/refactor` | Refactor code to meet project standards |
| `/stats-implement` | Implement statistical model from a specification |
| `/stats-review` | Review statistical analysis against the plan |
| `/worktree` | Manage git worktrees |
| `/performance-review` | Analyse agent/command usage in the conversation |
| `/mark-pr-agent` | Add draft notice to agent-generated PRs |
| `/read-up` | Read documentation entries noted in context |

## Skills (47 via marketplace)

Installed from [`seabbs/skills`](https://github.com/seabbs/skills)
across 9 plugins: research-academic, lang-r, lang-julia, lang-stan,
dev-workflow, github-ops, org-management, bot-automation, productivity.

See the [skills README](https://github.com/seabbs/skills#readme) for
the full list.
