Scan all repositories in $ARGUMENTS and identify issues that Claude code can efficiently handle.

**CLARIFYING QUESTIONS: Before proceeding, I may ask clarifying questions about:**
- Should I focus on specific types of issues? (bugs, features, documentation, tests)
- What difficulty level are you looking for? (quick wins, moderate challenges, learning projects)
- Are there particular programming languages or technologies to prioritise?
- Should I exclude certain repositories or focus on specific ones?
- What's your experience level with the codebases? (affects complexity recommendations)

## Phase 1: Repository Discovery
1. Find all git repositories in the folder recursively
2. For each repo, check if it has open issues: `gh issue list --repo [REPO] --state open`
3. Create a map of repo -> issues

## Phase 2: Issue Analysis
4. For each issue, analyse:
   - Labels (look for: bug, enhancement, documentation, refactor, tests)
   - Complexity indicators in description
   - File paths mentioned
   - Required domain knowledge

## Phase 3: Claude Code Suitability Scoring
5. Score each issue (0-10) based on:
   - Clear acceptance criteria (+3)
   - Limited scope (single file/component) (+2)
   - Test-related (writing/fixing tests) (+2)
   - Documentation updates (+2)
   - Code refactoring with clear patterns (+2)
   - No external API/service dependencies (+1)
   
6. Reduce score for:
   - Requires design decisions (-3)
   - Needs deep domain knowledge (-2)
   - Involves complex debugging (-2)
   - UI/UX design work (-3)
   - Requires human testing/verification (-1)

## Phase 4: Categorisation
7. Group issues by type:
   - Quick wins (score 8-10): Can be done in one session
   - Good candidates (score 6-7): Clear but need more time
   - Possible with help (score 4-5): Need human guidance
   - Not suitable (score <4): Better for human developers

## Phase 5: Actionable Report
8. Generate markdown report with:
   - Top 10 issues for Claude code (sorted by score)
   - For each issue:
     - Title and link
     - Repository
     - Why it's suitable
     - Estimated complexity
     - Suggested approach
   - Summary statistics by repository
   - Common patterns in suitable issues

## Phase 6: Automation Suggestions
9. Identify patterns for future automation:
   - Issue templates that work well
   - Labels that indicate Claude-friendly work
   - Repositories with many suitable issues

Focus on issues where success is highly likely. Start with the highest scored issues to build confidence.

**Note: I will ask clarifying questions about issue preferences and difficulty targets when they're not clear.**

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.