## Summary

- add first-class `init` task support to task creation with a dedicated brief template and blueprint
- keep `new.sh` default behavior unchanged for standard feature briefs
- cover the new init path and invalid type handling with automated tests

## Changes

- `scripts/new.sh` now accepts `--type <type>`, validates supported values, picks the matching template, and passes the chosen type to canvas creation.
- `scripts/canvas-add.sh`, `justfile`, `.ai/routing/policy.yaml`, and `vault/templates/brief.md` now recognize `init`.
- added `vault/templates/init-brief.md`, `.ai/blueprints/init-v1.md`, and expanded `tests/test_new.sh`.

## Test plan

- [x] Ran `bash tests/run_tests.sh`
- [x] Ran `./scripts/ai-check.sh`
- [x] Verified `new.sh TASK-ID` still produces `type: feature`
- [ ] Manual `just init DEMO-001`
- [ ] Manual `just go DEMO-001`

## Notes

- Worktree creation is blocked in this sandbox because `.git/refs` is read-only.
