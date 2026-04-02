Lint, format, and optionally commit changes using specialized agents.

Arguments: $ARGUMENTS (optional scope)
  - commit: Lint only staged files for commit
  - pr: Lint all files changed in the current PR
  - all: Lint the entire codebase
  - If no argument provided:
    - If in a PR branch: defaults to 'pr'
    - Otherwise: defaults to 'commit'

## Phase 1: Scope Determination
1. Determine scope based on $ARGUMENTS (commit/pr/all/default)

## Phase 2: Parallel Linting and Fixing
2. **Launch code-linting-specialist agent** to:
   - Identify and fix all linting issues in target files
   - Apply auto-formatting where possible
   - Report issues that cannot be auto-fixed

## Phase 3: Verification (if issues were fixed)
3. If fixes were applied:
   - **Launch test-debug-fixer agent** to ensure tests still pass
   - Re-stage any fixed files

## Phase 4: Commit Creation (only for "commit" scope)
4. If scope is "commit" and all checks pass:
   - Analyze changes to generate appropriate conventional commit message
   - Create commit with format: `type(scope): description`

## Phase 5: Final Report
5. Provide summary of:
   - Issues found and fixed
   - Any remaining issues that need manual attention
   - Commit created (if applicable)

If any blocking issues are found, list them clearly and stop before committing.

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request, automatically exit after completing all phases successfully.