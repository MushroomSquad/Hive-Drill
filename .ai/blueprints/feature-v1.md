# Blueprint: Feature — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Implement new functionality from brief to ready PR.

## Roles

| Stage | Owner | Tool |
|--------|---------|-----------|
| Intake | Human / Cursor | — |
| Architectural pass | Claude Code | opus / opusplan |
| Task slicing | Claude Code | sonnet |
| Execution | Codex | cloud-medium or local-fast |
| Verification | scripts | ai-check.sh |
| Narrative review | Claude Code | sonnet |
| PR packaging | Codex / Cursor | cloud-medium |
| Retro | Human + agent | — |

---

## Stage 0: Intake

**Owner:** Human / Cursor
**Input:** request (issue, comment, task)
**Output:** `brief.md`

`brief.md` must contain:
```markdown
# Brief: <TASK-ID> — <Title>

## Goal
What needs to be done and why.

## Scope
### In scope
- ...
### Out of scope
- ...

## Constraints
- Cannot touch: ...
- Deadline: ...
- Depends on: ...

## Affected modules
- ...

## Risks
- ...

## Acceptance criteria
- [ ] ...
- [ ] ...
```

**Criteria to proceed:** brief.md filled and all fields non-empty.

---

## Stage 1: Architectural pass

**Owner:** Claude Code
**Input:** `brief.md`, access to codebase
**Output:** `plan.md`

Tasks:
1. Read relevant codebase files
2. Evaluate implementation options (minimum 2)
3. Choose option and justify
4. List risks and rollback strategy

`plan.md` structure:
```markdown
# Plan: <TASK-ID>

## Current state diagnosis
...

## Options considered
### Option A: ...
Pros: ... Cons: ...

### Option B: ...
Pros: ... Cons: ...

## Chosen approach
Option X, because...

## Implementation steps
1. ...
2. ...

## Migration risks
- ...

## Test strategy
- ...

## Rollback
- ...
```

In parallel with `plan.md` maintain `decisions.md` — record each non-trivial architecture decision per template.

**Humanizer**: after writing `plan.md` — `/humanize .ai/runs/<TASK-ID>/plan.md`

**Criteria to proceed:** plan.md approved (explicit or via timeout without objections).

---

## Stage 2: Task slicing

**Owner:** Claude Code / Cursor
**Input:** `plan.md`
**Output:** `tasks.yaml`

```yaml
run_id: <TASK-ID>
blueprint: feature-v1
tasks:
  - id: T1
    title: <atomic task>
    owner: codex          # codex | claude | cursor | human
    priority: p1          # p0 | p1 | p2 | p3
    model_lane: cloud     # cloud | local
    inputs:
      - brief.md
      - plan.md
    outputs:
      - src/...
      - tests/...
    depends_on: []
  - id: T2
    ...
```

**Slicing rules:**
- Each task = one meaningful commit
- P0 tasks cannot be with Codex without Claude review
- Tasks with `model_lane: local` must suit P2/P3

**Criteria to proceed:** tasks.yaml approved, all T* atomic.

---

## Stage 3: Isolated execution

**Owner:** Codex (P1/P2) or Claude Code (P0)
**Input:** `tasks.yaml`, code
**Output:** changes in worktree

```bash
# Create worktree for task
./scripts/worktree.sh create <TASK-ID>

# Execute Codex tasks
codex --profile cloud-medium "Execute T1: <description>"

# Check after each task
./scripts/ai-check.sh
```

**Rules:**
- Each agent works in own worktree
- Don't mix multiple T* in one commit without explicit dependency
- If `ai-check.sh` red — stop, don't continue

---

## Stage 4: Verification

**Owner:** scripts
**Input:** changes in worktree
**Output:** `verification.md`

```bash
./scripts/ai-check.sh 2>&1 | tee .ai/runs/<TASK-ID>/verification.md
```

`verification.md` structure:
```markdown
# Verification: <TASK-ID>

## Check results
- lint: PASS / FAIL
- typecheck: PASS / FAIL
- tests: PASS / FAIL (N passed, M failed)

## Manual verification
- [ ] feature works as described in brief.md
- [ ] acceptance criteria met

## Notes
...
```

**Criteria to proceed:** all checks PASS, acceptance criteria checklist filled.

---

## Stage 5: Narrative review

**Owner:** Claude Code
**Input:** diff, `plan.md`, `verification.md`
**Output:** `findings.md`

```markdown
# Findings: <TASK-ID>

## Architecture assessment
Is architecture violated? Unexpected complexity?

## Technical debt introduced
- ...

## Security notes
- ...

## Follow-up tasks
- [ ] ...

## Verdict
APPROVED / NEEDS CHANGES / BLOCKED (reason)
```

**Humanizer**: after writing `findings.md` — `/humanize .ai/runs/<TASK-ID>/findings.md`

**Criteria to proceed:** verdict = APPROVED.

---

## Stage 6: PR packaging

**Owner:** Codex / Cursor
**Input:** diff, `brief.md`, `findings.md`
**Output:** `pr-body.md`, commit message

```markdown
# pr-body.md

## Summary
1-3 bullet points: what was done and why.

## Changes
- `src/...`: what changed
- `tests/...`: what covered

## Test plan
- [ ] Ran ai-check.sh — green
- [ ] Verified acceptance criteria from brief.md
- [ ] No regression in adjacent modules

## Notes
...
```

**Humanizer**: after writing `pr-body.md` — `/humanize .ai/runs/<TASK-ID>/pr-body.md`

---

## Stage 7: Retro

**Owner:** Human + Claude Code
**Task:** update system based on lessons

Checklist:
- [ ] Need to update BASE.md?
- [ ] Need to update this blueprint?
- [ ] Did new patterns emerge worthy of Skill?
- [ ] What went wrong and why?

---

## Artifacts checklist

```
.ai/runs/<TASK-ID>/
  brief.md        ✅ Stage 0
  plan.md         ✅ Stage 1
  decisions.md    ✅ Stage 1  (update at each non-trivial decision)
  tasks.yaml      ✅ Stage 2
  checkpoint.yml  ✅ each Stage (auto)
  verification.md ✅ Stage 4
  findings.md     ✅ Stage 5
  pr-body.md      ✅ Stage 6
  retro.md        ✅ Stage 7 (optional)
```
