# paper-summary

Provide a comprehensive summary of an academic paper using specialized agents.

## Usage

```bash
claude paper-summary <url_or_file_path>
```

## Description

This command uses the paper-analyzer agent to create a detailed, structured summary of an academic paper including:
- Overview and key contributions
- Highlights
- Notable strengths and weaknesses
- Section-by-section analysis with paragraph-level detail

The summary is saved as a markdown file with a meaningful title based on the paper's authors and topic.

## Process

1. **Launch paper-analyzer agent** with the provided URL or file path
2. The agent will:
   - Extract and analyze the paper's content
   - Create a comprehensive structured summary
   - Identify key insights and methodological details
   - Contextualize findings for researchers

## Output Format

The summary includes:
- **Overview**: High-level summary of the paper's contributions
- **Highlights**: Key findings and innovations
- **Strengths**: Notable positive aspects (bulleted)
- **Weaknesses**: Limitations or concerns (bulleted)
- **Detailed Summary**: Section-by-section breakdown with paragraph-level bullets

## Examples

```bash
# Summarize from URL
claude paper-summary https://arxiv.org/pdf/2301.12345.pdf

# Summarize from DOI
claude paper-summary 10.1038/s41586-024-07123-7

# Summarize local file
claude paper-summary ./papers/smith2024_covid_modelling.pdf
```

## Notes

- The output filename format is: `<FirstAuthor>_<Year>_<KeyTopic>_summary.md`
- The paper-analyzer agent handles various input formats (URLs, DOIs, local files)
- The agent provides comprehensive analysis optimized for research use