---
description: Standards for the Obsidian vault. Applied when reading, writing, or reviewing files in vault/.
globs:
  - "vault/**/*.md"
  - "vault/**/*.canvas"
  - "vault/**/*.json"
---

# Rules: vault/

## Format

- All notes: standard Obsidian-compatible Markdown
- All canvases: Obsidian Canvas JSON format (`nodes` + `edges` arrays)
- Do not use custom frontmatter keys not supported by Obsidian

## Canvas JSON schema

Valid canvas node types: `text`, `file`, `link`, `group`

```json
{
  "nodes": [
    { "id": "...", "type": "text", "text": "...", "x": 0, "y": 0, "width": 200, "height": 60 }
  ],
  "edges": [
    { "id": "...", "fromNode": "...", "toNode": "...", "label": "..." }
  ]
}
```

Never add non-standard top-level keys to canvas JSON — Obsidian will ignore them and they create noise.

## Directory structure

```
vault/projects/<project-name>/
  kanban.md          # Task board (Kanban plugin format)
  architecture.canvas  # System diagram
  decisions/         # Architecture decision records
  notes/             # Freeform research notes
```

Do not put pipeline run artifacts in the vault — those go in `.ai/runs/`.

## Modifying canvases

Use `scripts/canvas-add.sh`, `scripts/canvas-move.sh` — do not edit canvas JSON directly unless:
1. The script does not support the required operation
2. You document the manual edit in a decision record

## Kanban format

Kanban boards use the Obsidian Kanban plugin format:
```markdown
---
kanban-plugin: board
---

## Backlog
- [ ] Task name

## In Progress
- [ ] Task name

## Done
- [x] Task name
```

Column names must match exactly what `scripts/new.sh` generates.

## What not to do

- Do not commit `.obsidian/` workspace settings (already in .gitignore)
- Do not store secrets, API keys, or credentials in vault notes
- Do not use vault notes as a substitute for `.ai/runs/` artifacts
- Do not rename the `vault/projects/<name>/` structure — scripts depend on it
