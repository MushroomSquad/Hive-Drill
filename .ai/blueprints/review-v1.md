# Blueprint: PR Review — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Structured PR code review with issue classification.

## Roles

| Stage | Owner |
|--------|---------|
| Context loading | Claude Code |
| Automated checks | scripts |
| Narrative review | Claude Code |
| Findings output | Claude Code |

---

## Stage 0: Context loading

**Owner:** Claude Code
**Task:** understand what and why is changing

Read in this order:
1. PR description / `pr-body.md`
2. `brief.md` and `plan.md` from `.ai/runs/` if exists
3. Diff (not just `git diff`, but with context: `git diff --stat`, then by files)
4. Tests changed?
5. Adjacent files (imports, dependencies)

---

## Stage 1: Automated checks

```bash
./scripts/ai-check.sh
```

If red → record in findings as blocker.

---

## Stage 2: Narrative review

**Diff traversal template:**

For each changed module:
1. Logic correctness
2. Security (injection, auth, secrets)
3. Performance (N+1, unexpected allocations)
4. Test coverage
5. Architecture compliance (BASE.md, architecture-map.md)
6. Readability and code conventions

---

## Stage 3: Findings

**Output:** `findings.md`

**Issue classification:**

| Level | When | Requires action? |
|---------|-------|----------------|
| 🔴 **BLOCKER** | Bug, security issue, data loss risk, architecture violation | PR not merged |
| 🟡 **SUGGESTION** | Improvement worth making | Preferably fix |
| 💬 **NIT** | Style, minor readability | Optional |

```markdown
# Findings: PR-<ID>

## Overview
Brief description of changes and their quality.

## Automated checks
- lint: PASS / FAIL
- typecheck: PASS / FAIL
- tests: PASS / FAIL

## Issues

### 🔴 BLOCKER: <Title>
**File:** `src/...` line N
**Problem:** ...
**Fix:** ...

### 🟡 SUGGESTION: <Title>
**File:** `src/...`
**Why:** ...
**Option:** ...

### 💬 NIT: <Title>
...

## Security assessment
- [ ] No hardcoded secrets
- [ ] No SQL injection / XSS / command injection
- [ ] Auth / authz not bypassed
- [ ] No exposing internal data via API

## Architecture assessment
- [ ] Complies with architecture constraints from BASE.md
- [ ] No module boundary violations

## Verdict
APPROVED | REQUEST CHANGES | NEEDS DISCUSSION

**Reason:** ...
```

---

## Escalation triggers (→ human required)

- Any security-level BLOCKER
- Breaking change without migration guide
- DB schema change without DBA review
- Diff > 800 lines without clear plan

---

## Artifacts

```
.ai/runs/PR-<ID>/
  findings.md
```

---

## Writing standards

After writing `findings.md` — `/humanize`. See BASE.md § Writing standards.
