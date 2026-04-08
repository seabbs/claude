Run tests iteratively fixing code or tests until all pass, then commit.

Arguments: $ARGUMENTS (optional scope)
  - commit: Test only staged files
  - pr: Test all files changed in the current PR
  - all: Run full test suite
  - If no argument provided:
    - If in a PR branch: defaults to 'pr'
    - Otherwise: defaults to 'commit'

## Phase 1: Scope Determination and Test Discovery
1. Determine scope based on $ARGUMENTS:
   - If $ARGUMENTS is "commit": Focus on tests for staged files
   - If $ARGUMENTS is "pr": Focus on tests for PR changes
   - If $ARGUMENTS is "all": Run entire test suite
   - If no $ARGUMENTS: Check if on PR branch, default to "pr", otherwise "commit"

2. Discover test framework and commands:
   - Check package.json, Makefile, pytest.ini, testthat setup
   - Look for npm test, pytest, cargo test, julia test, R CMD check
   - Identify test file patterns (test_*.py, *.test.js, test-*.R)

3. Check for untested new features:
   - Identify new functions/classes/modules in changed files
   - Search for corresponding test files
   - Flag any new code without test coverage

## Phase 2: Create Missing Tests
4. For any new features without tests:
   - Analyse the feature's purpose and API
   - Look at existing test patterns in the codebase
   - Create appropriate test files following project conventions
   - Write comprehensive tests covering:
     * Happy path scenarios
     * Edge cases
     * Error handling
     * Any documented behaviour

## Phase 3: Iterative Test Fixing
5. Run relevant tests based on scope
6. For each failing test:
   - Analyse the failure message
   - Determine if it's a code issue or test issue:
     * New feature not covered: Update test
     * Bug in implementation: Fix code
     * Changed API: Update test expectations
     * Performance regression: Optimise code
   - Apply the fix
   - Re-run the specific failing test
   - Continue until test passes

7. After each fix, verify no other tests broke
8. Keep track of all changes made

## Phase 4: Final Verification
9. Run full test suite for changed files one more time
10. Ensure all tests pass consistently
11. Check test coverage if tools available
12. Verify all new features have adequate test coverage

## Phase 5: Commit Changes
13. Stage all files (code, tests, and any new test files)
14. Generate commit message:
    - If added new tests: `test: add tests for [feature]`
    - If mostly test fixes: `test: update tests for [feature]`
    - If mostly code fixes: `fix: resolve test failures in [component]`
    - If both: `fix: resolve issues and update tests for [feature]`
    - If comprehensive: `test: add missing tests and fix failures for [feature]`
15. Include details of what was added/fixed in commit body
16. Create the commit

## Important Considerations
- Use judgement on whether to fix code or tests based on:
  * Recent changes that might have broken tests
  * Whether test expectations seem reasonable
  * Whether the code behaviour is correct
- Don't blindly make tests pass - ensure fixes are meaningful
- If tests reveal actual bugs, prioritise fixing the code
- If tests are outdated, update them to match correct behaviour
- When creating new tests, follow existing patterns and conventions
- Ensure new tests are meaningful and not just for coverage
- Stop if encountering flaky tests or environment issues

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.