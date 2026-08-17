Always respond in UK English

## Identity
- Name: Sam Abbott
- GitHub handle: seabbs
- Bot account: seabbs-bot (signin@samabbott.co.uk)
- Code repositories are in ~/code
- GitHub orgs: cmmid, bristolmathmodellers, TuringLang, epiforecasts, HealthEconomicsHackathon, european-modelling-hubs, JuliaEpi, epinowcast, nfidd, EpiAware

## Git/GitHub
- Never push to main
- Global git identity is seabbs-bot (all commits default to bot)
- /commit adds Co-authored-by Sam Abbott (joint work)
- /commit --as-me commits as Sam Abbott only
- /commit --bot-only commits as seabbs-bot only (no co-author)
- Never include "🤖 Generated with [Claude Code]", "Co-Authored-By: Claude", "Co-Authored-By: Happy", or "via [Happy]" in commit messages or PR descriptions
- When creating worktrees do so as a subproject of the current project rather than at a higher dir level
- Use gh CLI to look up repos, create issues, and manage PRs even when not in the source repo (e.g. gh issue create -R seabbs/repo-name)
- Avoid `cd /path &&` before commands — gh works from worktrees without cd, use `git -C` for other repos, and `gh -R` for cross-repo operations
- Never pipe allowed commands through head/tail/grep/wc — piped commands don't match allow-list patterns and trigger permission prompts. Use built-in flags instead (e.g. `gh issue view --json`, `git log -n`)
- Commit and push changes before creating PRs
- Create GitHub issues for follow-up work discovered during implementation
- When creating issues or PRs as bot, add a note at the end: "This was opened by a bot. Please ping @seabbs for any questions."
- Run coderabbit review with: coderabbit review --plain
- For line-specific PR review comments use `gh api repos/{owner}/{repo}/pulls/{pr}/comments -f path=file -f body=comment -f commit_id=sha -f line=N -f side=RIGHT`
- When reviewing PRs, fetch inline review comments with `gh api repos/{owner}/{repo}/pulls/{pr}/comments` to see and respond to line-specific feedback

## jj (Jujutsu) + tuicr
- Some repos are colocated jj/git (a `.jj` dir beside `.git`); jj is a second view over the same git history, so the git-based worktree + PR flow is unchanged and stays primary
- jj does NOT read git's `user.*` — identity is set in `~/.config/jj/config.toml` (bot account)
- Task isolation stays `git worktree`; do NOT use `jj workspace` (mixing jj workspaces with git worktrees is fragile). A fresh git worktree has no `.jj` — to use jj tooling inside one, run `jj git init --colocate` (reversible with `rm -rf .jj`)
- Where a repo is colocated, prefer jj for shaping history within a working copy: `jj st`/`jj log` (no staging area; edits are already in `@`), `jj describe -m`, `jj commit -m` (≈ git commit), `jj split` (carve a mixed change into clean commits), `jj undo`
- Push/PR stays git + gh: `jj bookmark create feat/x -r @ && jj git push --bookmark feat/x`, then normal `gh pr create`; never point a bookmark at `main`
- If a repo is plain git (no `.jj`), use git as normal — do not run `jj git init`
- Review diffs a human will read through tuicr, not raw `git diff` — the `/tuicr` skill opens it in a tmux split; `review` is the shell alias (no args = working copy, a number = that PR, a range = those commits)
- The tuicr TUI belongs to the human: find their session with `tuicr review list --repo .` (`active: true`), read their feedback with `tuicr review comments --session <slug>`, and poll roughly every 30s while waiting. Treat `issue` as blocking, `suggestion` as consider-or-explain, `note` as a question
- Only write into a session when asked to review a patch yourself, and always with `--username` set so agent comments are distinguishable: `tuicr review add --session <slug> --target-file F --line N --type issue --username claude "…"`

## Review bot (seabbs-review-bot)
- A GitHub App identity, separate from seabbs-bot, so a review is not the PR author talking to itself; GitHub blocks APPROVE/REQUEST_CHANGES from the author
- `dotfiles/scripts/review-bot.sh` runs from cron every 5 minutes: it reviews open PRs by seabbs or seabbs-bot in seabbs, epinowcast, epiforecasts and EpiAware, once when the PR opens, and again only when seabbs (not the bot) comments `/review`
- A poll with nothing to do costs two API calls; both searches filter server side, so the cadence is cheap
- Drafts, PRs opened before the bot was switched on, PRs over 3000 changed lines, and anything labelled `no-review` are skipped
- The review runs Sonnet inside bwrap with a tmpfs home, so it cannot read `~/.ssh`, `~/.config/gh` or `~/code`, and its output is scanned for credential shapes before posting
- Do not post PR review findings as seabbs-bot; either let the review bot do it or keep the review local in tuicr
- Manual use: `review-bot.sh --pr owner/repo#N --dry-run` writes the review to `~/.local/share/review-bot/last-review.json` without posting; drop `--dry-run` to post; `--list` shows what the next run would pick up
- App credentials live in `~/.config/review-bot`; `review-bot-token.sh --check` verifies the app and lists its installations

## Workflow
- Use parallel subagents where possible (subject to compute headroom — see Compute awareness), each with relevant /skills in their prompt
- Before implementing new features, search codebase for existing similar functionality
- Follow Red/Green TDD: write a failing test, commit, make it pass, commit, refactor, commit
- Commit after each small unit of completed work without waiting to be asked
- Run tests before committing code changes (failing tests are expected for red TDD commits)
- Run the language-standard linter on changed files before committing and fix all issues
- Ask clarifying questions when requirements are ambiguous rather than making assumptions
- If a Taskfile.yml exists, use it for common tasks (build, test, lint, etc.) via the `task` command
- On project setup, create a Taskfile.yml to manage common development tasks
- Subagent skill mapping: R work → /r-development, Julia → /julia-development, Stan → /stan-development, code changes → /lint + /test, code review → /review, GitHub issues → /issue-summary, statistical models → /stats-implement + /stats-review, academic revision → /academic-revise, literature → /literature-search, verification → /check-requirements
- When reading symlinked files, use the local path within the project (e.g. `context/file.R`) not the resolved target path

## Compute awareness (shared hosts)
- Some hosts (e.g. the archie agents hub) run several agents at once and can be overloaded into unresponsiveness
- A PreToolUse hook (`~/.claude/hooks/compute-guard.sh`) blocks subagent spawns and heavy build commands when load is red; it fails open and only trips when the box is genuinely oversubscribed
- Before fanning out or starting a big build, check headroom: `~/.claude/hooks/compute-budget.sh` prints a verdict (green/amber/red) and a recommended max parallel count
- When red: run builds serially, cut subagent fan-out, and wait for load to fall; remediation commands (e.g. pkill) are never blocked
- Override only when you are sure the box is fine: `echo green > ~/.cache/compute-budget-force`, then `rm` it afterwards

## Prose formats (Markdown, Quarto, TeX)
- One sentence per line; no 80-char wrapping
- Use `@placeholder` for missing references

## All languages
- Max 80 chars per line for code
- No trailing whitespace
- No spurious blank lines

## Writing style
- Avoid LLM indicator words: comprehensive, practitioner(s), framework (when vague), current approaches, leverage, facilitate, robust, novel, landscape, utilize, foster, harness, streamline, pivotal, nuanced, multifaceted, cornerstone, synergy, overarching
- Minimise colon use in prose; only use when genuinely needed
- Minimise use of - for punctuation
- Keep sentences short. Split into separate sentences rather than joining clauses with semicolons, dashes or commas
- No run-on sentences
- Say each point once. Do not restate a point already made
- When editing existing text, make the minimal change. Do not rewrite surrounding prose that did not need to change
- Prefer simple, direct prose without adjectives. Example:

"Recent outbreaks of Ebola, COVID-19 and mpox have demonstrated the value of modelling for synthesising data for rapid evidence to inform decision making.
Methods used to synthesise available data in real time broadly fall into two classes: either combining results from multiple, smaller models calibrated in isolation (the _pipeline approach_, e.g., [@huisman2022]), or representing a single model tuned to the specific scenario (the _joint model_ approach, e.g., [@birrell2024;@Watson2024-vj]).

Both approaches have downsides.
Research has demonstrated that joint modelling of data sources provides significant advantages over combining estimates from separate models by mitigating error propagation, improving reasoning, and ensuring proper uncertainty quantification [@lison2024].
However, such models tend to be monolithic and designed for specific problems and settings.
To adapt or extend such models, analysts need to fully comprehend all parts of the corresponding model and code, creating barriers to sharing methodology and leading to inefficient re-implementation when parts of a model could, in principle, be re-used."