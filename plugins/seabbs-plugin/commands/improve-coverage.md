Improve test coverage for $ARGUMENTS.

**CLARIFYING QUESTIONS: Before proceeding, I may ask clarifying questions about:**
- What coverage target are you aiming for? (e.g., 80%, 90%)
- Which areas should I prioritise? (critical functions, edge cases, error handling)
- Do you prefer unit tests, integration tests, or both?
- Are there specific testing patterns or frameworks I should follow?

## Phase 1: Coverage Analysis
1. Generate coverage report
2. Identify untested:
   - Functions
   - Branches
   - Error paths
   - Edge cases

## Phase 2: Test Priority
3. Prioritise by:
   - Critical business logic
   - Complex functions
   - Error handling
   - Public APIs

## Phase 3: Test Generation
4. For each untested area:
   - Write comprehensive test cases
   - Include edge cases
   - Test error conditions
   - Add property-based tests where appropriate

## Phase 4: Test Quality
5. Ensure tests:
   - Are independent
   - Have clear names
   - Test one thing
   - Use appropriate assertions
   - Run quickly

## Phase 5: Integration
6. Run full test suite
7. Check coverage improvement
8. Refactor tests for maintainability

Generate tests that actually catch bugs, not just increase numbers. Focus on behaviour, not implementation.

**Note: I will ask clarifying questions about coverage targets and testing priorities when they're not clear.**

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.