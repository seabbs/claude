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
- Never include "🤖 Generated with [Claude Code]" or "Co-Authored-By: Claude" in commit messages, PR descriptions, or issue bodies
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
- Some repos are colocated jj/git (a `.jj` dir beside `.git`). Git stays primary for worktrees and PRs; jj is for shaping history in a working copy (`jj st`, `jj describe`, `jj commit`, `jj split`, `jj undo`)
- jj does NOT read git's `user.*` — identity is in `~/.config/jj/config.toml`
- Task isolation stays `git worktree`, never `jj workspace`. A fresh worktree has no `.jj`; add one with `jj git init --colocate`, undo with `rm -rf .jj`. Plain-git repos stay plain
- Push and PR stay git + gh; never point a bookmark at `main`
- Diffs a human will read go through tuicr rather than raw `git diff` — see the `/tuicr` skill

## Review bot (seabbs-review-bot)
- A GitHub App reviews PRs by seabbs or seabbs-bot when they open, and again on request when either comments `@seabbs-review-bot`. The `bot-report` skill covers how it runs and how to audit it
- Act on its reviews: fix what it gets right, say explicitly which findings you reject and why, and verify each against the source yourself rather than on its say-so — it has caught real bugs and has also been wrong from its own truncated greps
- Where acting on a finding would reverse a decision I made explicitly, do the rest and put that one back to me with the new information rather than silently flipping it
- Never post your own review findings as seabbs-bot; let the review bot do it, or keep the review local in tuicr

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
- Prefer under ~80 chars per line for new code; wrap at natural points
  (call args, chained methods, boolean operators), never mid-token or
  mid-string.
- For markdown quarto etc prefer one sentence a line.
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
- Prefer simple, direct prose without adjectives.