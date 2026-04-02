I need you to create a pull request based on issue #$ARGUMENTS. Follow these steps systematically:

## Phase 0: Setup and Worktree Decision
1. **Ask the user:** "Do you want to use a git worktree for this issue? (y/n)"
   - If yes: Launch worktree-manager agent to create worktree for issue-$ARGUMENTS
   - If no: Create a new branch in the current repository: `git checkout -b issue-$ARGUMENTS-[brief-description]`

## Phase 1: Issue Analysis and Complexity Assessment
2. **First, analyze the issue (REQUIRED FIRST STEP):**
   - github-issue-analyzer: Analyze issue #$ARGUMENTS for comprehensive understanding and requirements

3. **Assess complexity based on the analysis:**
   Determine which tier this issue falls into:

   **SIMPLE** (minimal workflow):
   - Single file changes
   - Typos, comments, or documentation-only fixes
   - Single line code changes
   - No tests required or trivial test updates

   **MEDIUM** (streamlined workflow):
   - Small features (2-5 files)
   - Bug fixes affecting multiple files
   - Documentation with minor code changes
   - Standard test updates required

   **COMPLEX** (full workflow):
   - New features with multiple components
   - Architectural changes
   - Statistical implementations or research code
   - Multiple interconnected systems
   - Requires comprehensive testing strategy

4. **Execute workflow based on complexity tier:**

### FOR SIMPLE ISSUES:
- Skip detailed planning documents
- codebase-navigator: Quick search for relevant code areas
- Implement changes directly
- Basic linting check only
- Skip to Phase 4 (PR creation)

### FOR MEDIUM ISSUES:
- **Launch supporting agents in parallel:**
  - codebase-navigator: Search codebase for relevant code areas
  - context-mining-researcher: Search for relevant project context
- **Create lightweight plan** (no file, keep in memory):
  - Issue summary and acceptance criteria
  - Files to modify
  - Basic testing approach
- **Skip extensive planning iterations**
- Continue to Phase 2 (Implementation)

### FOR COMPLEX ISSUES:
- **Write analysis to file:** Save the github-issue-analyzer output to `issue_analysis_$ARGUMENTS.md`
- **Launch supporting agents in parallel:**
  - codebase-navigator: Search codebase for relevant code areas
  - context-mining-researcher: Search for relevant project context
- **Launch feature-planning-orchestrator** with gathered context for comprehensive implementation plan
- **Create planning document** `pr_plan_issue_$ARGUMENTS.md` including:
  - Reference to detailed issue analysis
  - Issue summary and acceptance criteria
  - Detailed implementation approach with code snippets
  - Specific file modifications with before/after examples
  - API signatures and data structures
  - Integration patterns and architectural decisions
  - Testing strategy
  - Potential edge cases with handling approaches
- **Iterate on the plan** if refinements needed:
  - Re-launch feature-planning-orchestrator with feedback
  - Update `pr_plan_issue_$ARGUMENTS.md`
  - Repeat until plan comprehensively addresses all requirements
- Continue to Phase 2 (Implementation)

## Phase 2: Implementation
5. **Execute implementation:**
   - Primary agents for implementation:
     - **statistical-implementation-specialist**: For statistical/research code
     - **test-debug-fixer**: For writing and fixing tests
   - Alternative agents for specific needs:
     - academic-revision-specialist: For scientific writing/documentation
     - general-purpose agent: Only for non-statistical utility code
   - For independent tasks: Launch agents in parallel
   - For dependent tasks: Launch agents sequentially
     - Implement feature → Write/run tests → Fix based on test results
     - Each iteration may require code-refactoring-specialist based on feedback

## Phase 3: Quality Assurance (Complexity-based)

### FOR SIMPLE ISSUES:
6. **Basic quality checks:**
   - code-linting-specialist: Check uncommitted changes
   - test-debug-fixer: Run tests if applicable
   - Skip other review agents

### FOR MEDIUM ISSUES:
7. **Launch core review agents in parallel:**
   - code-linting-specialist: Check uncommitted changes
   - documentation-updater: Update documentation to match code changes
   - code-review-expert: Perform code review
   - test-debug-fixer: Ensure all tests pass
   - requirements-compliance-checker: Verify implementation matches issue requirements

### FOR COMPLEX ISSUES:
8. **Launch comprehensive review agents in parallel:**
   - code-linting-specialist: Check uncommitted changes
   - documentation-updater: Update documentation to match code changes
   - code-review-expert: Perform thorough code review
   - statistical-analysis-reviewer: If statistical code was implemented
   - test-debug-fixer: Ensure all tests pass
   - requirements-compliance-checker: Verify implementation matches original issue requirements
   - academic-writing-reviewer: If academic documentation was modified
   - grant-spec-reviewer: If working on grant-funded project deliverables

## Phase 4: Final Verification and PR Creation
9. Fix any issues identified by the review agents
10. **Self-review with pr-review-analyzer:** Review the completed work as if it were someone else's PR (skip for SIMPLE issues)
11. Verify all acceptance criteria are met
12. **Clean up planning documents** (COMPLEX only): `rm pr_plan_issue_$ARGUMENTS.md issue_analysis_$ARGUMENTS.md`
13. **Launch pr-engineer agent** to:
    - Create well-structured commits for all changes
    - Push the branch
    - Create the pull request with title "Fix #$ARGUMENTS: [Clear description]"
    - Include comprehensive description of changes, testing, and issue resolution
    - **IMPORTANT:** Prepend this notice to the PR description:
      ```
      **This is entirely from an agent so do not review until I have pinged for review as I will do a first pass**
      ```

Throughout this process, the agents will handle the detailed work while you coordinate their efforts and ensure all acceptance criteria are met.