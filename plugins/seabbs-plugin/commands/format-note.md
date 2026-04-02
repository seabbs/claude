# format-note

Format an existing Obsidian note with appropriate tags and link it from today's daily note.

## Usage

```bash
claude format-note <note_path>
```

## Description

This command formats an existing note in your Obsidian unpublished folder by:
- Adding appropriate tags based on content analysis
- Ensuring proper frontmatter structure
- Adding a link to the note from today's periodic daily note

## Process

1. Reads the existing note from the unpublished folder
2. Analyzes content to determine appropriate tags
3. Updates/adds frontmatter with:
   - Tags based on content
   - Creation date
   - Modified date
   - Status: unpublished
4. Locates today's daily note in the periodic notes folder
5. Adds a link to the formatted note in the daily note

## Tag Detection

The command analyzes note content to suggest tags such as:
- Topic tags (e.g., #research, #coding, #ideas)
- Type tags (e.g., #article, #reference, #project)
- Domain tags based on content keywords

## Daily Note Integration

Adds entry to daily note in format:
```
- [[Note Title]] - Brief description #type
```

## Examples

```bash
# Format a note in unpublished folder
claude format-note ~/Obsidian/unpublished/new-research-idea.md

# Format with custom tag suggestions
claude format-note ~/Obsidian/unpublished/meeting-notes.md --tags "meeting,project-x"
```

## Implementation Details

The command:
1. Uses Read to access the note content
2. Analyzes text for keyword extraction and tagging
3. Updates frontmatter using YAML format
4. Locates daily note using current date
5. Appends link if not already present

## Vault Location

Default path: `/Users/lshsa2/Library/CloudStorage/GoogleDrive-s.e.abbott12@gmail.com/My Drive/cloud/apps/obsidian`

## Expected Vault Structure

```
obsidian/
├── periodic/
│   └── YYYY-MM-DD.md (daily notes)
├── unpublished/
│   └── your-notes-here.md
└── published/
```

## Notes

- Uses Google Drive synced Obsidian vault at the path above
- Daily notes expected in format: `periodic/YYYY-MM-DD.md`
- Preserves existing content while adding/updating metadata
- Can override vault path with `--vault-path` option

## Auto-Exit When Standalone
**IMPORTANT**: If this command is being run as a standalone request (i.e., the user's message contains only this command and no other instructions), automatically exit after completing all phases successfully. Do not continue the conversation or ask for further instructions.