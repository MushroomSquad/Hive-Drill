---
description: Format and schema rules for pipeline blueprints. Applied when reading, writing, or reviewing files in .ai/blueprints/.
globs:
  - ".ai/blueprints/**/*.md"
  - ".ai/blueprints/*.md"
---

# Rules: .ai/blueprints/

## Required frontmatter

Every blueprint must start with:

```markdown
# Blueprint: <Name> — <version>
**Status:** stable | draft | deprecated
**Last updated:** YYYY-MM-DD
```

## Required sections (in order)

1. `## Purpose` — one paragraph, what this blueprint accomplishes
2. `## Roles` — table mapping stage → owner → tool
3. Numbered stages (`## Stage 0: ...` through `## Stage N: ...`)
4. `## Artifacts checklist` — list of all artifacts with the stage that produces them

## Stage format

Each stage block must contain:
- `**Owner:**` — which agent runs this (Claude Code | Codex | scripts | Human)
- `**Input:**` — what the stage reads
- `**Output:**` — what the stage produces
- `**Criteria to proceed:**` — gate condition before moving to next stage

## Owner labeling

Use consistent owner labels — do not invent new names:

| Label | Meaning |
|-------|---------|
| `Claude Code` | Claude Code CLI (architect or reviewer role) |
| `Codex` | Codex CLI (executor role) — specify profile when relevant |
| `scripts` | Bash scripts in `scripts/` |
| `Human` | Requires human action |
| `Codex / Cursor` | Either tool acceptable |

## Artifact paths

All artifact paths must follow the pattern:
```
.ai/runs/<TASK-ID>/<artifact>.md
```

Never reference root-level artifact paths.

## Versioning

- Blueprint filename format: `<type>-v<N>.md`
- When making breaking changes — create a new version file, don't overwrite
- Mark the old version `**Status:** deprecated` and point to the new one

## What not to do

- Do not add optional stages without a gate condition
- Do not remove the `## Roles` table — it is used by `blueprint-run.sh`
- Do not change artifact frontmatter field names (task_id, status, verdict)
