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

Settings files are managed by Claude Code at runtime and not tracked.

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

## Related

- [`seabbs/skills`](https://github.com/seabbs/skills) -- 47 skills across 9 plugins
- [`seabbs/dotfiles`](https://github.com/seabbs/dotfiles) -- parent dotfiles repo
