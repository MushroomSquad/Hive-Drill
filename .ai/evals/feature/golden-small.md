# Eval: Feature — Small (Golden)
**Blueprint:** feature-v1
**Difficulty:** small
**Type:** add simple utility

---

## Input
Add function `chunk_list(lst, size)` that splits list into chunks of given size.

## Expected artifacts
- `brief.md` with all fields filled
- `plan.md` with implementation options
- `tasks.yaml` with at least 1 task
- Implementation + test
- `verification.md`: all PASS
- `findings.md`: APPROVED

## Eval criteria

| Criterion | Minimum | Good |
|---------|---------|--------|
| brief.md filled | ✅ all fields | — |
| Test exists | ✅ passes | Edge cases covered |
| ai-check.sh | ✅ PASS | — |
| findings.md | ✅ APPROVED | No excess criticism |
| Extra changes | 0 files besides needed | — |

## Eval scoring
- 0 = not done
- 1 = partially
- 2 = completely

Score >= 8/10 → blueprint works for this task type.
