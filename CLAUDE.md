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
- Commit and push changes before creating PRs
- Create GitHub issues for follow-up work discovered during implementation
- When creating issues or PRs as bot, add a note at the end: "This was opened by a bot. Please ping @seabbs for any questions."
- Run coderabbit review with: coderabbit review --plain

## Workflow
- Use parallel subagents where possible, each with relevant /skills in their prompt
- Before implementing new features, search codebase for existing similar functionality
- Follow Red/Green TDD: write a failing test, make it pass, refactor
- Run tests before committing code changes
- Run the language-standard linter on changed files before committing and fix all issues
- Ask clarifying questions when requirements are ambiguous rather than making assumptions
- If a Taskfile.yml exists, use it for common tasks (build, test, lint, etc.) via the `task` command
- On project setup, create a Taskfile.yml to manage common development tasks
- Subagent skill mapping: R work → /r-development, Julia → /julia-development, Stan → /stan-development, code changes → /lint + /test, code review → /review, GitHub issues → /issue-summary, statistical models → /stats-implement + /stats-review, academic revision → /academic-revise, literature → /literature-search, verification → /check-requirements

## Markdown
- One sentence per line
- Use `@placeholder` for missing references

## All languages
- Max 80 chars per line (except Markdown, Quarto, and .qmd where one sentence per line takes priority)
- No trailing whitespace
- No spurious blank lines

## Writing style
- Avoid LLM indicator words: comprehensive, practitioner(s), framework (when vague), current approaches, leverage, facilitate, robust, novel, landscape, utilize, foster, harness, streamline, pivotal, nuanced, multifaceted, cornerstone, synergy, overarching
- Minimise colon use in prose; only use when genuinely needed
- Minimise use of - for punctuation
- Prefer simple, direct prose without adjectives. Example:

"Recent outbreaks of Ebola, COVID-19 and mpox have demonstrated the value of modelling for synthesising data for rapid evidence to inform decision making.
Methods used to synthesise available data in real time broadly fall into two classes: either combining results from multiple, smaller models calibrated in isolation (the _pipeline approach_, e.g., [@huisman2022]), or representing a single model tuned to the specific scenario (the _joint model_ approach, e.g., [@birrell2024;@Watson2024-vj]).

Both approaches have downsides.
Research has demonstrated that joint modelling of data sources provides significant advantages over combining estimates from separate models by mitigating error propagation, improving reasoning, and ensuring proper uncertainty quantification [@lison2024].
However, such models tend to be monolithic and designed for specific problems and settings.
To adapt or extend such models, analysts need to fully comprehend all parts of the corresponding model and code, creating barriers to sharing methodology and leading to inefficient re-implementation when parts of a model could, in principle, be re-used."