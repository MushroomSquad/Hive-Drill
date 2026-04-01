# Blueprint: Bugfix — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Diagnose and fix a bug with mandatory reproduction test.

**Key rule:** test is written BEFORE fix. No test — no fix.

## Roles

| Stage | Owner |
|--------|---------|
| Triage | Codex local (P2) or Claude (P0) |
| Diagnosis | Claude Code |
| Fix + Test | Codex |
| Verification | scripts |
| Review | Claude Code |
| PR | Codex / Cursor |

---

## Stage 0: Triage

**Owner:** Codex local-fast (P2) or Claude (if P0)
**Output:** `brief.md` with classification

```markdown
# Brief: <BUG-ID> — <Bug description>

## Symptom
What is broken, how to reproduce.

## Priority
P0 (critical) | P1 (important) | P2 (routine)

## Classification
- [ ] Regression (what broke it?)
- [ ] Edge case
- [ ] Integration issue
- [ ] Data issue
- [ ] Unknown

## Affected area
- ...

## Reproduction steps
1. ...
2. ...
3. Expected: ... / Actual: ...

## Risks
- Affected users: ...
- Data at risk: yes / no
```

**P0 triggers** (→ immediately escalate to Claude + human):
- Data leak
- Data loss
- Security vulnerability
- Production down

---

## Stage 1: Diagnosis

**Owner:** Claude Code
**Input:** `brief.md`, codebase
**Output:** `plan.md` with root cause

```markdown
# Plan: <BUG-ID>

## Root cause
Exact cause: where, why, how to reproduce.

## Fix approach
Minimal fix: what to change.

## Test strategy
Reproduction test: how to write so it's RED BEFORE fix.

## Regression risk
What may break nearby.

## Rollback
How to rollback if fix breaks something else.
```

---

## Stage 2: Test-first execution

**Owner:** Codex
**Order:**
1. Write reproduction test → ensure RED
2. Write minimal fix → ensure GREEN
3. Run full suite → ensure no regressions

```bash
# T1: reproduction test (must be RED)
codex "Write a failing test that reproduces <BUG-ID> based on plan.md"

# Check that test is red:
./scripts/ai-check.sh --tests-only

# T2: fix (test must turn GREEN)
codex "Fix <BUG-ID> based on plan.md root cause"

# Full check:
./scripts/ai-check.sh
```

---

## Stage 3: Verification

Similar to feature-v1 Stage 4.
Additionally in `verification.md`:

```markdown
## Bug-specific verification
- [ ] Reproduction test was RED before fix (confirmed)
- [ ] Reproduction test GREEN after fix
- [ ] Regression suite green
- [ ] Root cause documented
```

---

## Stage 4: Review

**Owner:** Claude Code
**Output:** `findings.md`

Additionally to standard findings:

```markdown
## Root cause confirmed
...

## Systemic issue?
Is this a single bug or symptom of systemic problem?

## Prevention
What to add to BASE.md / ai-check / tests to catch this class of bugs earlier?
```

---

## Stage 7: Workspace cleanup

**Owner:** scripts
**Input:** current workspace root
**Output:** clean workspace root

Rules:
- Generated documents must be written under `.ai/runs/<BUG-ID>/...` or `${AI_RUNS_DIR}/${BUG-ID}/...`
- If a transient workspace file is needed, write it under `_ai_tmp/` (for example `_ai_tmp/PR_DESCRIPTION.md`)
- Run `scripts/cleanup.sh` after PR packaging or any manual packaging step

---

## Artifacts

```
.ai/runs/<BUG-ID>/
  brief.md
  plan.md
  verification.md
  findings.md
  pr-body.md
```

---

## Writing standards

After writing each document — `/humanize`. See BASE.md § Writing standards.
