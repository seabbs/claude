Post a helpful reply to issue #$ARGUMENTS.

**CLARIFYING QUESTIONS: Before proceeding, I may ask clarifying questions about:**
- What tone should the reply take? (formal, casual, technical)
- What level of technical detail is appropriate?
- Are there specific aspects of the issue you want me to focus on?
- Should I provide code examples or just conceptual guidance?

## Phase 1: Context Gathering
1. Read the full issue: `gh issue view $ARGUMENTS --repo [REPO]`
2. Read all comments: `gh issue view $ARGUMENTS --comments --repo [REPO]`
3. Check issue labels, assignees, and project status

## Phase 2: Reply Analysis
4. Determine the appropriate type of reply:
   - Answer to a question
   - Status update
   - Technical clarification
   - Request for more information
   - Solution proposal

## Phase 3: Reply Drafting
5. Draft a reply that:
   - Directly addresses the last comment/question
   - Is concise and actionable
   - Uses appropriate technical detail
   - Maintains professional, helpful tone
   - Includes code examples if relevant

## Phase 4: Pre-flight Checks
6. Review the draft for:
   - Accuracy of technical information
   - Clarity of communication
   - No unintended commitments
   - Appropriate mentions (@username) if needed

## Phase 5: Posting
7. Post the comment using: `gh issue comment $ARGUMENTS --body "[DRAFTED_CONTENT]" --repo [REPO]`

Always be helpful, constructive, and move the conversation forward. If uncertain about something, acknowledge it and ask for clarification.

**Note: I will ask clarifying questions when the best approach isn't clear from the issue context.**