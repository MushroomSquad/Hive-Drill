# PR: BUG-001

## Summary
Tighten Stage 1 plan validation so malformed Claude output is replaced with the plan template, and fix Stage 6 PR packaging so namespaced run directories are passed through to `package-pr.sh` instead of falling back to the legacy flat path.

## Changes
- prepend the no-filesystem-tools directive at the top of the Stage 1 planning prompt
- replace the size-only `plan.md` acceptance check with frontmatter and section validation
- restore the plan template and stop the pipeline when Stage 1 output is invalid
- add optional `RUN_DIR` support to `scripts/package-pr.sh`
- pass the namespaced run dir from `stage_pr()`
- add tests for namespaced and legacy PR packaging, malformed-plan fallback, and a `just go` smoke fixture

## Test plan
- [x] `bash tests/test_package_pr.sh`
- [x] `bash tests/test_go_pipeline.sh`
- [x] `./scripts/ai-check.sh`

## Manual verification
- [x] Stage 1 generated a valid `plan.md` with frontmatter and `## Implementation steps`
- [x] Stage 6 no longer emitted `[ERR] Run not found` for a namespaced project run dir
