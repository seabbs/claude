# claude

Personal Claude Code configuration.
Skills live in the [`seabbs/skills`](https://github.com/seabbs/skills) marketplace; this repo holds everything else.

## Contents

```
CLAUDE.md   # Global instructions (identity, workflow, style)
commands/   # 9 slash commands
link.sh     # Symlink config into ~/.claude/
setup.sh    # Marketplace registration + plugin installation
```

Settings files (`settings.json`, `settings.local.json`) are managed
by Claude Code at runtime and not tracked.

## Setup

This repo is a submodule of [`seabbs/dotfiles`](https://github.com/seabbs/dotfiles) at `claude/`.

```bash
# 1. Clone dotfiles with submodules
git clone --recurse-submodules https://github.com/seabbs/dotfiles.git

# 2. Create symlinks
dotfiles/scripts/link.sh

# 3. Install plugins from marketplace
~/.claude/setup.sh

# 4. Generate helper scripts (inside Claude Code)
/setup-scripts
```

### What gets symlinked

```
~/.claude/CLAUDE.md  -> dotfiles/claude/CLAUDE.md
~/.claude/commands/  -> dotfiles/claude/commands
```

## Commands

| Command | Description |
|---|---|
| `/academic-revise` | Revise academic text from reviewer comments |
| `/check-requirements` | Verify work against original requirements |
| `/mark-pr-agent` | Add draft notice to agent-generated PRs |
| `/performance-review` | Analyse agent/command usage in the conversation |
| `/read-up` | Read documentation entries noted in context |
| `/refactor` | Refactor code to meet project standards |
| `/stats-implement` | Implement statistical model from a specification |
| `/stats-review` | Review statistical analysis against the plan |
| `/worktree` | Manage git worktrees |

## Skills (47 via marketplace)

Installed from [`seabbs/skills`](https://github.com/seabbs/skills) across 9 plugins.

| Plugin | Skills | Area |
|---|---|---|
| `research-academic` | 8 | Papers, literature, grants, minutes |
| `dev-workflow` | 10 | Commits, linting, testing, review, PRs, docs |
| `org-management` | 10 | CI, deps, issues, releases, standards |
| `productivity` | 7 | Notes, news, planning, cleanup |
| `github-ops` | 6 | Dashboard, issues, repo analysis |
| `bot-automation` | 3 | Bot tasks, daily summaries |
| `lang-r` | 1 | R package development |
| `lang-julia` | 1 | Julia package development |
| `lang-stan` | 1 | Stan probabilistic programming |

Third-party plugins (humanizer, feature-dev) are installed separately via `setup.sh`.

## Related

- [`seabbs/skills`](https://github.com/seabbs/skills) -- plugin marketplace
- [`seabbs/dotfiles`](https://github.com/seabbs/dotfiles) -- parent dotfiles repo
