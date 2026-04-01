---
task_id: BUG-002
status: done
agent: codex
created: 2026-03-31
---

# Verification: BUG-002

## Audit results

Audited scripts:
- `scripts/package-pr.sh`
- `scripts/plan-init.sh`
- `scripts/self.sh`
- `scripts/blueprint-run.sh`
- `scripts/go.sh`
- `scripts/gate.sh`
- `scripts/canvas-move.sh`
- `scripts/cleanup.sh`
- `scripts/init.sh`

Output path inventory:
- `scripts/package-pr.sh`
  - Persistent artifact: `${RUN_DIR}/pr-body.md`
  - Transient workspace file: `${PROJECT_ROOT}/_ai_tmp/PR_DESCRIPTION.md`
- `scripts/plan-init.sh`
  - `${PROJECT_ROOT}/.ai/runs/<TASK-ID>/brief.md`
  - `${PROJECT_ROOT}/.ai/runs/<TASK-ID>/tasks.yaml`
  - `${PROJECT_ROOT}/.ai/runs/<TASK-ID>/decisions.md`
- `scripts/self.sh`
  - `${PROJECT_ROOT}/.ai/self/config.json`
  - `${PROJECT_ROOT}/workspace/hive-drill-dev/` during clone/update
- `scripts/blueprint-run.sh`
  - No direct file writes in the script body; delegates to `plan-init.sh`, `worktree.sh`, and external tools
- `scripts/go.sh`
  - `${RUN_DIR}/checkpoint.yml`, `plan.md`, `tasks.md`, `codex.log`, `test-report.md`, `findings.md`
  - Temp prompt files via `mktemp`
  - Removes `${WORKTREE_PATH}/_ai_tmp` at pipeline start and on `EXIT`
- `scripts/gate.sh`
  - Updates frontmatter in the reviewed artifact under `.ai/runs/...` or the vault
- `scripts/canvas-move.sh`
  - Updates the vault canvas under `vault/projects/<project>/canvas/`
- `scripts/cleanup.sh`
  - Deletes `${PWD}/PR_DESCRIPTION.md`, `${PWD}/scaffold.py`, and `${PWD}/_ai_tmp`
- `scripts/init.sh`
  - Writes `.env`
  - Writes `.gitignore`

Disposition:
- `package-pr.sh` was the only transient write site that needed redirection; it now materializes `PR_DESCRIPTION.md` only under `_ai_tmp/`.
- `go.sh` now runs PR packaging inside the target worktree, resets `_ai_tmp` before the run, and traps cleanup on exit.
- `cleanup.sh` now removes stale `_ai_tmp/` in addition to legacy root files.
- `plan-init.sh`, `self.sh`, `blueprint-run.sh`, `gate.sh`, and `canvas-move.sh` did not require `_ai_tmp` redirection because they either write to `.ai/`, the vault, `.ai/self/`, or a workspace clone intentionally.
- `init.sh` intentionally writes project-root setup files and now adds `_ai_tmp/` to `.gitignore`.

## Implementation checks

- [x] `scripts/package-pr.sh` writes the persistent PR body to `.ai/runs/.../pr-body.md`
- [x] `scripts/package-pr.sh` creates `_ai_tmp/PR_DESCRIPTION.md` in the target worktree
- [x] `gh pr create` reads `--body-file` from `_ai_tmp/PR_DESCRIPTION.md`
- [x] `scripts/go.sh` runs `package-pr.sh` from `${TARGET_ROOT}` so `_ai_tmp/` lands in the target repo, not the Hive Drill repo
- [x] `scripts/go.sh` removes stale `_ai_tmp/` before the pipeline starts
- [x] `scripts/go.sh` traps `_ai_tmp/` cleanup on both clean exit and error
- [x] `scripts/cleanup.sh` removes stale `_ai_tmp/`
- [x] `.gitignore` and `scripts/init.sh` include `_ai_tmp/`
- [x] `.ai/blueprints/bugfix-v1.md` and `.ai/blueprints/feature-v1.md` document `_ai_tmp/` for transient workspace files
- [x] `scripts/ai-check.sh` fails when `_ai_tmp/` is still present

## Test evidence

- [x] `bash tests/test_package_pr.sh`
- [x] `bash tests/test_cleanup.sh`
- [x] `bash tests/test_go_pipeline.sh`
- [x] `bash tests/run_tests.sh`
- [x] `./scripts/ai-check.sh`

## Manual verification

- [x] Regression coverage proves `_ai_tmp/` is absent after a clean pipeline run
- [x] Regression coverage proves `_ai_tmp/` is absent after a late failure via the `EXIT` trap
- [x] `.ai/runs/<TASK-ID>/pr-body.md` and `_ai_tmp/PR_DESCRIPTION.md` content flow is covered by the packaging test
- [ ] Live `just go BUG-005` verification was not executed in this sandboxed session

## Outcome

- [x] All tests pass
- [x] Linter clean
- [x] `scripts/ai-check.sh` exits 0 on a clean repo and exits non-zero when `_ai_tmp/` is present
- [x] No active read-site still points `gh pr create` at a root-level `PR_DESCRIPTION.md`
- [x] PR description is written as a durable run artifact and mirrored to `_ai_tmp/PR_DESCRIPTION.md` only for the transient workspace step
