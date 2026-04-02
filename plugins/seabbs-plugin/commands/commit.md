Create a well-structured commit using the specialized commit-engineer agent.

## Process

1. **Launch commit-engineer agent** to:
   - Review staged and unstaged changes
   - Create appropriate commit messages following conventional format
   - Handle staging of files (excluding temporary/generated files)
   - Push changes to the appropriate branch
   - Never push directly to main

The agent will:
- Analyze changes to determine commit type (feat, fix, docs, etc.)
- Write clear, descriptive commit messages
- Follow project conventions from CLAUDE.md
- Ensure clean git history

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request, automatically exit after completing all phases successfully.