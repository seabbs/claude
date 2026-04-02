Check that all code has appropriate documentation using specialized agents.

Arguments: $ARGUMENTS (optional scope)
  - commit: Check only staged files
  - pr: Check all files changed in the current PR
  - all: Check the entire codebase
  - If no argument provided:
    - If in a PR branch: defaults to 'pr'
    - Otherwise: defaults to 'commit'

## Phase 1: Scope Determination
1. Determine scope based on $ARGUMENTS (commit/pr/all/default)

## Phase 2: Parallel Documentation Analysis
2. **Launch agents in parallel based on file types in scope:**
   - code-review-expert: Identify functions/classes lacking documentation
   - academic-writing-reviewer: Check quality of existing documentation
   - context-mining-researcher: Extract project documentation standards from CLAUDE.md

## Phase 3: Documentation Generation and Updates
3. For identified gaps:
   - Generate documentation following project conventions
   - Apply language-specific formats (roxygen2, docstrings, JSDoc)
   - Use `@inheritParams` in R to avoid duplication

4. **For R projects:** Run `devtools::document()` to update man/ files

## Phase 4: Quality Verification
5. **Launch code-linting-specialist** to verify:
   - Documentation format compliance
   - Build checks for documentation
   - No broken references

## Phase 5: Report Results
6. Provide summary of:
   - Files checked and documentation coverage
   - Documentation added or updated
   - Any issues requiring attention

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request, automatically exit after completing all phases successfully.