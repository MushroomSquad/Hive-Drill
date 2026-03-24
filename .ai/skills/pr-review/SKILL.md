# Skill: PR Review (Quick)
**Owner:** Claude Code (P1)
**When to use:** Быстрый review PR без полного pipeline. Для небольших изменений.

---

## Task
Структурированный review diff'а с выводом findings.

## Input required
- PR diff (или `git diff <base>..<head>`)
- PR description / title
- Опционально: brief.md / plan.md

## Steps

1. Прочитать PR description
2. `git diff --stat` — понять масштаб
3. Читать diff по файлам, применять checklist:

```
For each changed file:
☐ Logic correctness
☐ Security (injection, auth, secrets exposure)
☐ Error handling (if applicable)
☐ Test coverage (new logic is tested)
☐ API contract (no unintentional breaking changes)
☐ Naming and conventions (per BASE.md)
```

4. Записать findings по формату review-v1.md Stage 3

## Output: `findings.md`

Минимальный вариант для quick review:
```markdown
# Quick Review: <PR title>

## Verdict
APPROVED / REQUEST CHANGES / NEEDS DISCUSSION

## Issues (if any)
🔴 BLOCKER: ...
🟡 SUGGESTION: ...
💬 NIT: ...

## Security: OK / CONCERN
## Tests: ADEQUATE / MISSING
```

## Time budget
- Diff < 100 lines: < 5 min
- Diff 100-300 lines: 10-15 min
- Diff > 300 lines: use full review blueprint
