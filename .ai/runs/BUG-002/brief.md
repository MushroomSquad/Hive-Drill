# Brief: BUG-002 - Clean up root-level AI artifacts from pipeline workspaces

_Created: 2026-03-31 | Blueprint: bugfix_

## Goal
Stop pipeline scripts from leaving transient AI-generated files in workspace roots. Keep PR body output in `.ai/runs/`, add a cleanup stage, and lock the behavior with regression tests.

## Scope
### In scope
- Audit the listed scripts for write targets
- Move PR body generation to run artifacts
- Add workspace cleanup and tests
- Update blueprint docs and fallback ignore rules

### Out of scope
- Broader pipeline refactors
- Changing artifact schemas

## Constraints
- Minimal, focused changes only
- Preserve existing script behavior outside artifact path cleanup
- Keep file writes under `.ai/runs/<TASK-ID>/` where applicable

## Affected modules
- scripts/package-pr.sh
- scripts/plan-init.sh
- scripts/blueprint-run.sh
- scripts/go.sh
- scripts/init.sh
- tests/
- .ai/blueprints/

## Risks
- Stage numbering in docs and pipeline output changes
- Tests may assume old PR packaging behavior

## Acceptance criteria
- [ ] PR body is created under `.ai/runs/.../pr-body.md`
- [ ] Workspace cleanup removes `PR_DESCRIPTION.md` and `scaffold.py`
- [ ] Pipeline regression tests confirm clean workspace roots
