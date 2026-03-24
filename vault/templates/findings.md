---
task_id: <!-- FILL: task id -->
verdict: APPROVED
# verdict options: APPROVED | REQUEST_CHANGES | BLOCKED
agent: claude
reviewed_at: <!-- FILL: YYYY-MM-DD -->
---

# Review Findings: <!-- FILL: task title -->

## Architecture assessment

<!-- How does this change fit the existing architecture?
     Is the approach sound? Does it follow established patterns? -->

**Overall**: <!-- summary judgment -->

### What works well
-

### Concerns
-

## Technical debt introduced

<!-- List any shortcuts taken, TODOs left, or degradation in code quality.
     Rate each item: low / medium / high debt. -->

| Item | Debt level | Ticket / follow-up |
|---|---|---|
| <!-- describe --> | low/med/high | <!-- link or TASK-ID --> |

## Security notes

<!-- Any authentication, authorization, injection, or data exposure issues?
     Mark as: OK / WARNING / BLOCKER -->

- <!-- area -->: <!-- status and notes -->

## Performance notes

<!-- Any latency, memory, or throughput concerns? -->

- <!-- note or "No concerns identified" -->

## Follow-up tasks

<!-- Things that MUST or SHOULD be done after this task merges -->

- [ ] <!-- follow-up 1 -->
- [ ] <!-- follow-up 2 -->

## Verdict

> **<!-- APPROVED / REQUEST_CHANGES / BLOCKED -->**

<!-- Required changes before merge (if REQUEST_CHANGES or BLOCKED): -->

1. <!-- required change or "None" -->

---

> **Next step**:
> - APPROVED → `just go <task_id> --from-stage 6` (create PR)
> - REQUEST_CHANGES → address items above, re-run stage 5
> - BLOCKED → escalate before proceeding
