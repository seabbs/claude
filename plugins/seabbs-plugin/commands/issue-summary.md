Summarise the conversation in issue #$ARGUMENTS with special focus on the last message.

**CLARIFYING QUESTIONS: Before proceeding, I may ask clarifying questions about:**
- What specific aspects of the conversation should I focus on?
- Do you need a high-level overview or detailed technical summary?
- Are there particular decisions or outcomes you want highlighted?
- Should I emphasise action items or technical details?

## Phase 1: Issue Retrieval
1. Fetch the issue details: `gh issue view $ARGUMENTS --repo [REPO]`
2. Get all comments: `gh issue view $ARGUMENTS --comments --repo [REPO]`

## Phase 2: Conversation Analysis
3. Create a timeline summary:
   - Original issue description and key requirements
   - Major discussion points and decisions
   - Any code snippets or technical details shared
   - Resolution attempts or blockers identified

## Phase 3: Last Message Focus
4. Quote the last message verbatim in a highlighted block
5. Analyse the last message for:
   - New requirements or changes
   - Questions that need answering
   - Action items mentioned
   - Tone/urgency indicators

## Phase 4: Summary Report
6. Create a structured summary:
   - Issue title and metadata
   - Brief conversation history (bullet points)
   - Last message (verbatim in quote block)
   - Current status and next steps
   - Any unresolved questions

## Phase 5: Actionable Insights
7. Based on the conversation, suggest:
   - Immediate actions needed
   - Clarifications to request
   - Potential solutions if applicable

Focus on making the current state crystal clear, especially what the last commenter is asking for or stating.

**Note: I will ask clarifying questions when the summary focus or depth isn't clear from the context.**

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.