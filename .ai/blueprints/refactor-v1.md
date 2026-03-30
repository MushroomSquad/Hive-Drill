# Blueprint: Refactor — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Change code structure without changing behavior.

**Golden rule:** behavior before = behavior after. Tests before = tests after.
Refactoring without tests is just code change.

## Roles

| Stage | Owner |
|--------|---------|
| Scope definition | Claude Code |
| Safety net check | Codex / scripts |
| Execution | Codex (step by step) |
| Verification | scripts |
| Architecture review | Claude Code |

---

## Stage 0: Scope definition

**Output:** `brief.md`

```markdown
# Brief: <TASK-ID> — Refactor: <description>

## Motivation
Why refactor needed (tech debt, readability, performance, coupling).

## Scope
### What we change
- ...
### What we DON'T change (behavior)
- ...
### Out of scope
- ...

## Success metric
How will situation measurably improve after refactor?
(complexity metric, coverage, build time, etc.)

## Risks
- Regressions: ...
- Diff size: expected ~N lines
```

**STOP if:**
- Scope not clearly defined
- No tests for changed code (need to add first)
- Expected diff > 1000 lines (split into multiple tasks)

---

## Stage 1: Safety net

**Owner:** Codex / scripts
**Task:** ensure tests cover changed code

```bash
# Coverage before refactor (record)
./scripts/ai-check.sh --coverage > .ai/runs/<TASK-ID>/coverage-before.txt

# If coverage < threshold → first add tests
```

---

## Stage 2: Incremental execution

**Rule:** refactor done step by step. Each step must be atomic and verifiable.

Typical steps (select needed ones):
1. Extract method / function
2. Rename (with finding all uses)
3. Move to module
4. Split class / file
5. Simplify condition
6. Remove duplication (DRY)
7. Replace pattern

```bash
# After each step:
./scripts/ai-check.sh
git add -p && git commit -m "refactor: <step description>"
```

---

## Stage 3: Verification

Additionally to standard:

```markdown
## Refactor-specific verification
- [ ] All tests pass (none deleted)
- [ ] Behavior unchanged (acceptance test / smoke test)
- [ ] Metric improved: <before> → <after>
- [ ] No new TODO without TICKET-ID
```

---

## Stage 4: Architecture review

**Output:** `findings.md` with improvement assessment

```markdown
## Improvement assessment
Before: ...
After: ...

## Was refactor goal achieved?

## New risks?

## Recommendations for next steps
```

---

## Artifacts

```
.ai/runs/<TASK-ID>/
  brief.md
  coverage-before.txt
  verification.md
  findings.md
  pr-body.md
```

---

## Writing standards

After writing each document — `/humanize`. See BASE.md § Writing standards.
