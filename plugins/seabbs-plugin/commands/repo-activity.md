# repo-activity

Provide a comprehensive analysis of GitHub repository activity and current state.

## Usage

```bash
claude repo-activity [<owner/repo>]
```

If no repository is specified, the command will:
1. Check if the current directory is a git repository
2. Extract the GitHub remote URL to identify the repository
3. Analyze that repository

Falls back to error if not in a git repository and no repo is specified.

## Description

This command provides an in-depth analysis of repository activity including:
- Open issues with labels, assignees, and recent comments
- Issue activity trends and response times
- Active pull requests with review status
- PR merge patterns and review metrics
- Contributor activity and engagement
- Recent commits and release activity

The analysis uses GitHub's API to gather comprehensive data and presents actionable insights about the repository's health and activity patterns.

## Output Sections

### Issues Analysis
- Total open/closed issues
- Issues by priority/label
- Recently active issues (last 7 days)
- Stale issues (no activity >30 days)
- Average time to close
- Top issue contributors

### Pull Request Analysis
- Open PRs with review status
- Recently merged PRs (last 7 days)
- PR review turnaround time
- PRs awaiting review
- Draft PRs
- PR size distribution

### Activity Metrics
- Commit frequency
- Active contributors (last 30 days)
- Code review participation
- Release cadence
- Community engagement metrics

### Detailed Summaries
- Each open issue with latest comment preview
- Each open PR with review status and changes summary
- Recent discussions and decisions

## Implementation Details

The command:
1. Checks for repository context using `git remote -v` if no repo specified
2. Parses GitHub URL from remote to extract owner/repo
3. Creates a todo list for systematic analysis
4. Uses `gh api` to fetch comprehensive repository data
5. Analyzes patterns in issue and PR lifecycle
6. Identifies bottlenecks and areas needing attention
7. Generates a markdown report with actionable insights

## Output Format

Results are presented in a structured markdown file named `<repo>-activity-<date>.md` containing:
- Executive summary with key metrics
- Detailed sections for each analysis area
- Visualized trends using text-based charts
- Actionable recommendations based on patterns

## Examples

```bash
# Analyze current repository
claude repo-activity

# Analyze specific repository
claude repo-activity anthropics/claude-code

# Analyze with custom time windows
claude repo-activity --days 14
```

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.