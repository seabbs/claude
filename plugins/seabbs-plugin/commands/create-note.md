# create-note

Import a markdown file into your Obsidian library and format it as a note.

## Usage

```bash
claude create-note <source_markdown_path> [<target_name>]
```

## Description

This command imports an external markdown file into your Obsidian library by:
- Moving/copying the file to the unpublished folder
- Renaming it if a target name is provided
- Running format-note to add tags and link from daily note

## Process

1. Reads the source markdown file
2. Determines target filename (uses source name if not specified)
3. Creates a copy in the Obsidian unpublished folder
4. Runs format-note command to:
   - Add appropriate tags
   - Set up frontmatter
   - Link from today's daily note

## File Naming

- Spaces replaced with hyphens
- Special characters removed
- Lowercase conversion for consistency
- Date prefix added if duplicate exists

## Integration

After import, the note will be:
- Located in `Obsidian/unpublished/`
- Tagged based on content analysis
- Linked from today's daily note
- Ready for further editing in Obsidian

## Examples

```bash
# Import with original filename
claude create-note ~/Downloads/interesting-article.md

# Import with new name
claude create-note ~/Documents/research.md "quantum-computing-overview"

# Import from URL (downloads first)
claude create-note https://example.com/blog-post.md
```

## Vault Location

Default path: `/Users/lshsa2/Library/CloudStorage/GoogleDrive-s.e.abbott12@gmail.com/My Drive/cloud/apps/obsidian`

## Options

- `--vault-path`: Specify custom Obsidian vault location
- `--folder`: Target folder within vault (default: unpublished)
- `--tags`: Additional tags to include

## Notes

- Uses Google Drive synced Obsidian vault at the path above
- Preserves original file (creates copy)
- Handles conflicts by appending date
- Supports importing from URLs via download
- Automatically calls format-note after import