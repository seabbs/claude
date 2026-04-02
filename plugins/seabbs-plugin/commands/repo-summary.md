# repo-summary

Provide a comprehensive analysis of a GitHub repository combining activity metrics with code development insights.

## Usage

```bash
claude repo-summary [<owner/repo>]
```

If no repository is specified, the command will:
1. Check if the current directory is a git repository
2. Extract the GitHub remote URL to identify the repository
3. Analyze that repository

Falls back to error if not in a git repository and no repo is specified.

## Description

This command builds on repo-activity to provide a complete repository analysis including:
- All GitHub activity metrics (issues, PRs, contributors)
- Git development patterns and history
- Code evolution and commit patterns
- Branch strategies and release cycles
- Development velocity and trends

## Output Sections

### Repository Overview
- Project description and key metrics
- Technology stack and languages
- Repository age and size
- Star/fork/watch counts

### Development Activity (Git Analysis)
- Commit frequency and patterns (daily/weekly/monthly)
- Active development periods
- Code churn metrics
- File change hotspots
- Author contribution distribution
- Branch lifecycle patterns

### GitHub Activity (from repo-activity)
- Issue and PR metrics
- Community engagement
- Review turnaround times
- Release patterns

### Code Evolution
- Lines of code trends
- Major refactoring periods
- Technical debt indicators
- Test coverage trends (if available)
- Documentation updates

### Development Insights
- Development velocity trends
- Bus factor analysis
- Time to merge patterns
- Release frequency and stability
- Areas of active development

## Implementation Details

The command:
1. Runs repo-activity to gather GitHub metrics
2. Uses git log analysis for development patterns
3. Analyzes commit messages for semantic patterns
4. Identifies code hotspots using git statistics
5. Correlates GitHub activity with development patterns
6. Generates unified markdown report

## Output Format

Results are presented in a markdown file named `<repo>-summary-<date>.md` containing:
- Executive summary with key insights
- Detailed metrics with visualizations
- Development timeline
- Actionable recommendations
- Health indicators

## Examples

```bash
# Analyze current repository
claude repo-summary

# Analyze specific repository
claude repo-summary anthropics/claude-code

# Include extended history
claude repo-summary --months 12
```

## Notes

- Combines GitHub API data with local git analysis
- Provides holistic view of repository health
- Identifies patterns that may not be visible from GitHub alone
- Useful for due diligence, onboarding, or project assessment

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.