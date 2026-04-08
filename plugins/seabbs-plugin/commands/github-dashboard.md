Give me a GitHub dashboard update. Follow these steps:

## Phase 1: Notifications Analysis
1. Use gh cli to fetch my notifications: `gh api notifications`
2. Group notifications by repository and type (issue, PR, mention, etc.)
3. Prioritise by:
   - Direct mentions
   - Review requests
   - CI failures on my PRs
   - Updates on issues I created
   - Updates on subscribed threads

## Phase 2: PR Status Check
4. Check status of all my open PRs: `gh pr list --author @me --state open`
5. For each PR, check:
   - Review status
   - CI status
   - Merge conflicts
   - Time since last update
6. List PRs that need my action

## Phase 3: Issue Triage
7. List issues assigned to me: `gh issue list --assignee @me`
8. Check for new issues in repos I maintain that need triage
9. Flag any overdue or blocked issues

## Phase 4: Summary Report
10. Create a markdown summary with:
    - Action items (what needs immediate attention)
    - Review requests
    - CI failures to fix
    - Upcoming deadlines
    - Quick stats (PRs merged this week, issues closed)
11. Suggest priority order for the day

Start with the most important items and work down. If I need to navigate to specific items, provide direct gh cli commands or URLs.

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.