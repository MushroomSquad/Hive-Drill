---
task_id: BUG-001
status: done
---

# Verification: BUG-001

## Automated checks
- [x] `bash tests/test_package_pr.sh`
- [x] `bash tests/test_go_pipeline.sh`
- [x] `./scripts/ai-check.sh`

## Manual verification
- [x] Stage 1 invalid-plan fallback restores `plan.md` from template with frontmatter and `## Implementation steps`
- [x] Stage 1 prompt directive is not leaked into generated `plan.md`
- [x] Stage 6 namespaced PR packaging succeeds when `RUN_DIR` is `.ai/runs/<project>/<TASK-ID>`
- [x] Legacy flat `.ai/runs/<TASK-ID>` packaging still succeeds without a second argument

## Smoke fixture
- Entry point: `just go FEAT-001` in a throwaway fixture repo with mocked `claude`, `codex`, `gh`, `npm`, `npx`
- Result: exit `0`
- Result: generated `plan.md` line 1 was `---`
- Result: generated `plan.md` contained `## Implementation steps`
- Result: generated `plan.md` did not contain `Do NOT call any filesystem tools`
- Result: Stage 6 created `pr-body.md`
- Result: pipeline log contained no `[ERR] Run not found`
