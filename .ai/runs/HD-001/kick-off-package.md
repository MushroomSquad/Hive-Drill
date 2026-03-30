---
task_id: HD-001
status: ready
---

# Kick-off Package: HD-001

## Scope shipped

- Added a dedicated init brief template with `type: init`, 15 sections, required/optional markers, and the standard draft-to-ready footer.
- Added `.ai/blueprints/init-v1.md` covering intake, discovery, architecture synthesis, backlog generation, canvas setup, kick-off package, and retro.
- Extended `scripts/new.sh` with `--type <type>`, template selection, type validation, and typed canvas card creation.
- Updated canvas type support, `just init`, routing policy, and brief type options.
- Added regression coverage for init creation, invalid types, and the unchanged default feature path.

## Validation

- Automated tests: PASS
- `ai-check`: PASS

## Constraints

- The repository’s required worktree flow could not be exercised here because the sandbox blocks writes under `.git/refs`.
- Manual Obsidian verification was not run in this session.
