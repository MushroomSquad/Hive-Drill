# Blueprint: Init — v1
**Status:** draft
**Last updated:** 2026-03-30

---

## Purpose
Initialize a project or workspace from intake through a ready kick-off package.

## Roles

| Stage | Owner | Tool |
|--------|---------|-----------|
| Intake | Human / Cursor | — |
| Discovery | Claude Code | opus |
| Architecture synthesis | Claude Code | opusplan |
| Backlog generation | Claude Code | sonnet |
| Canvas setup | Human / Cursor | Obsidian |
| Kick-off package | Human + agent | Markdown |
| Retro | Human + agent | — |

## Stage 0: Intake

**Owner:** Human / Cursor
**Input:** project idea, workspace request, or initialization note
**Output:** `brief.md`

Fill `brief.md` from `vault/templates/init-brief.md`.

**Criteria to proceed:** all required sections are filled and `status: ready`.

## Stage 1: Discovery

**Owner:** Claude Code
**Input:** `brief.md`, repository or project context
**Output:** `discovery.md`

Tasks:
1. Validate the business context and problem framing.
2. Gather constraints, dependencies, and unknowns.
3. Surface open questions that need human answers.
4. Summarize what already exists and what must be created.

**Criteria to proceed:** discovery risks and unanswered questions are visible.

## Stage 2: Architecture synthesis

**Owner:** Claude Code
**Input:** `brief.md`, `discovery.md`
**Output:** `architecture.md`

Tasks:
1. Propose the initial system shape and responsibility boundaries.
2. Record non-negotiable decisions and rejected alternatives.
3. Define the first implementation slices needed for delivery.

**Criteria to proceed:** architecture direction is concrete enough to plan work.

## Stage 3: Backlog generation

**Owner:** Claude Code
**Input:** `brief.md`, `discovery.md`, `architecture.md`
**Output:** `tasks.yaml`, `roadmap.md`

Tasks:
1. Convert the init brief into an ordered backlog.
2. Split work into phases or task groups with dependencies.
3. Mark which items need human approval before execution.

**Criteria to proceed:** backlog is actionable and sequenced.

## Stage 4: Canvas setup

**Owner:** Human / Cursor
**Input:** `tasks.yaml`, `roadmap.md`
**Output:** updated project canvas

Tasks:
1. Create or update the project canvas.
2. Place init cards and architecture anchors.
3. Verify links and labels are readable in Obsidian.

**Criteria to proceed:** canvas reflects the initialization backlog.

## Stage 5: Kick-off package

**Owner:** Human + agent
**Input:** `brief.md`, `discovery.md`, `architecture.md`, `tasks.yaml`, canvas updates
**Output:** `kick-off-package.md`, `pr-body.md`

Tasks:
1. Summarize the initial direction and decision record.
2. Package backlog, constraints, and first execution steps.
3. Write the PR description or handoff narrative for the init pass.

**Criteria to proceed:** package is ready for review or handoff.

## Stage 6: Retro

**Owner:** Human + agent
**Input:** kick-off package, decisions taken during init
**Output:** `retro.md`

Tasks:
1. Capture what was unclear or slow during initialization.
2. Note missing templates, scripts, or policy gaps.
3. Queue follow-up improvements.

**Criteria to complete:** retro is captured and follow-up items are visible.
