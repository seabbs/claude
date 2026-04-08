Review and update project dependencies safely.

## Phase 1: Dependency Audit
1. List all outdated dependencies
2. Check for security vulnerabilities
3. Identify breaking changes in major updates

## Phase 2: Update Strategy
4. Categorise updates:
   - Security patches (immediate)
   - Minor updates (safe)
   - Major updates (needs testing)
   
5. For each major update:
   - Read changelog
   - Identify breaking changes
   - Find migration guides

## Phase 3: Incremental Updates
6. Update in order:
   - Security patches first
   - Development dependencies
   - Minor production updates
   - Major updates one at a time

7. After each update group:
   - Run full test suite
   - Check for deprecation warnings
   - Test key functionality manually

## Phase 4: Documentation
8. Update:
   - Lock files
   - README if setup changed
   - Migration notes for team

Create a PR for each logical group of updates with clear description of changes and testing performed.

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.