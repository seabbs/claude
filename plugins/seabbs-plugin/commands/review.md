Perform a comprehensive code review using specialized agents.

**CLARIFYING QUESTIONS: Before proceeding, I may ask clarifying questions about:**
- What level of review depth do you want? (quick scan, thorough analysis, security focus)
- Are there specific concerns to focus on? (performance, maintainability, security, style)
- Should I prioritise critical issues or provide comprehensive feedback?

Arguments: $ARGUMENTS (optional scope)
  - commit: Review only staged files for commit
  - pr: Review all files changed in the current PR
  - all: Review the entire codebase
  - If no argument provided:
    - If in a PR branch: defaults to 'pr'
    - Otherwise: defaults to 'commit'

## Phase 1: Scope Determination
1. Determine scope based on $ARGUMENTS (commit/pr/all/default)

## Phase 2: Parallel Agent Execution
2. **Launch specialized review agents in parallel based on scope:**
   - code-linting-specialist: Check for style, formatting, and quality issues
   - code-review-expert: Comprehensive code review with project context
   - test-debug-fixer: Verify test coverage and quality (if tests affected)
   - statistical-analysis-reviewer: Review statistical implementations (if applicable)
   - academic-writing-reviewer: Review documentation and comments (if applicable)

## Phase 3: Synthesis and Reporting
3. Collect and synthesize feedback from all agents
4. Organize findings by priority:
   - Critical issues (must fix)
   - Important improvements (should fix)
   - Suggestions (consider fixing)
   - Positive observations

For each issue, provide location, description, suggested fix, and rationale.

**Note: The specialized agents will handle the detailed analysis while I coordinate their efforts and present unified feedback.**