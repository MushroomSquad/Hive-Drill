---
task_id: HD-001
type: feature
status: in_progress
created: 2026-03-30
owner: codex
---

# Brief: HD-001 — Project Initialization Brief Type

## Goal

Add first-class `init` task support to task creation and routing so project initialization work can use its own brief template, blueprint, and routing bucket without changing existing `feature` behavior.

## Scope

### In scope
- Add an init brief template and init blueprint.
- Update task creation flow to accept `--type init`.
- Wire `init` through canvas, `just`, routing policy, and brief type options.
- Add automated coverage for `new.sh` init behavior and invalid type handling.

### Out of scope
- Changes to `go.sh` execution semantics beyond routing data consumed later.
- Refactors unrelated to init task support.

## Constraints

- Keep changes minimal and consistent with existing Bash/Markdown style.
- Preserve current default behavior when `--type` is omitted.
- Worktree creation is blocked in this sandbox because `.git/refs` is read-only, so execution happens in the current checkout.

## Acceptance criteria

- [ ] `./scripts/new.sh --type init <TASK-ID>` creates an init brief from a dedicated template.
- [ ] `./scripts/new.sh <TASK-ID>` still defaults to a feature brief.
- [ ] Routing policy contains an init discovery bucket with human approval required.
- [ ] Tests and `scripts/ai-check.sh` pass.
