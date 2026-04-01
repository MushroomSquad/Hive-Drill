# PR: BUG-002

## Summary
- Move transient PR-description handling under `_ai_tmp/PR_DESCRIPTION.md` inside the target worktree instead of the worktree root.
- Reset and trap-clean `_ai_tmp/` from `scripts/go.sh` so stale files are removed on both success and failure.
- Add regression coverage and an `ai-check` contract so leftover `_ai_tmp/` fails the gate.

## Changes
- `scripts/package-pr.sh`: keep `pr-body.md` in `.ai/runs/...` and mirror it to `_ai_tmp/PR_DESCRIPTION.md` for `gh pr create`.
- `scripts/go.sh`: run PR packaging in the target worktree, reset `_ai_tmp/` at start, and register an `EXIT` trap for cleanup.
- `scripts/cleanup.sh`: remove stale `_ai_tmp/` alongside legacy root files.
- `scripts/init.sh`, `.gitignore`, `scripts/ai-check.sh`, blueprints, and tests: codify the `_ai_tmp/` contract and guard against regressions.

## Test plan
- [x] Ran `bash tests/run_tests.sh`
- [x] Ran `./scripts/ai-check.sh`
- [x] Verified clean-exit and failure-path `_ai_tmp/` cleanup in `tests/test_go_pipeline.sh`
