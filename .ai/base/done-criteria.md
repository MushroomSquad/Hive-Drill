# Definition of Done — Detailed Criteria

## By Task Type

### Feature
- [ ] Code written, all tests pass
- [ ] New logic covered by tests (unit / integration)
- [ ] `scripts/ai-check.sh` green
- [ ] `brief.md`, `plan.md`, `tasks.yaml`, `verification.md`, `pr-body.md` filled
- [ ] No TODO without TICKET-ID
- [ ] CHANGELOG updated (if behavior changed)
- [ ] No secrets in code or commits

### Bug fix
- [ ] Reproduction test written **before** fix
- [ ] Test passes **after** fix
- [ ] Root cause documented in `findings.md`
- [ ] Regression risk assessed
- [ ] `scripts/ai-check.sh` green

### Refactor
- [ ] Behavior unchanged (tests before = tests after)
- [ ] Complexity metrics not increased (if measured)
- [ ] No new public API without documentation
- [ ] `scripts/ai-check.sh` green

### PR Review
- [ ] All P0 issues documented
- [ ] `findings.md` filled structurally
- [ ] Reviewer points split into: blocker / suggestion / nit
- [ ] Final verdict: approve / request-changes / needs-discussion

### Release
- [ ] All planned tasks in done
- [ ] `scripts/ai-check.sh` on release branch green
- [ ] CHANGELOG filled
- [ ] Migration guide (if breaking changes)
- [ ] Rollback plan documented

## General rules for all types

| Rule | Mandatory |
|---------|------------|
| No hardcoded secrets | ✅ always |
| No console.log / print debug | ✅ always |
| No commented-out code | ✅ always |
| Worktree cleaned after PR | ✅ after merge |
| Artifacts in `.ai/runs/` | ✅ always |
