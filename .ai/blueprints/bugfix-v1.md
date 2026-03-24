# Blueprint: Bugfix — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Диагностика и исправление бага с обязательным воспроизводящим тестом.

**Ключевое правило:** тест пишется ДО фикса. Если нет теста — нет фикса.

## Roles

| Стадия | Владелец |
|--------|---------|
| Triage | Codex local (P2) или Claude (P0) |
| Diagnosis | Claude Code |
| Fix + Test | Codex |
| Verification | scripts |
| Review | Claude Code |
| PR | Codex / Cursor |

---

## Stage 0: Triage

**Владелец:** Codex local-fast (P2) или Claude (если P0)
**Выход:** `brief.md` с классификацией

```markdown
# Brief: <BUG-ID> — <Описание бага>

## Symptom
Что именно сломано, как воспроизвести.

## Priority
P0 (critical) | P1 (important) | P2 (routine)

## Classification
- [ ] Regression (что сломало?)
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
- Затронутые пользователи: ...
- Данные под угрозой: yes / no
```

**P0 триггеры** (→ немедленно эскалировать к Claude + человеку):
- Утечка данных
- Потеря данных
- Security vulnerability
- Production down

---

## Stage 1: Diagnosis

**Владелец:** Claude Code
**Вход:** `brief.md`, codebase
**Выход:** `plan.md` с root cause

```markdown
# Plan: <BUG-ID>

## Root cause
Точная причина: где, почему, как воспроизводится.

## Fix approach
Минимальный фикс: что изменить.

## Test strategy
Воспроизводящий тест: как написать, чтобы он был красным ДО фикса.

## Regression risk
Что может сломаться рядом.

## Rollback
Как откатить если фикс сломает что-то ещё.
```

---

## Stage 2: Test-first execution

**Владелец:** Codex
**Порядок:**
1. Написать воспроизводящий тест → убедиться что RED
2. Написать минимальный фикс → убедиться что GREEN
3. Запустить полный suite → убедиться нет регрессий

```bash
# T1: воспроизводящий тест (должен быть RED)
codex "Write a failing test that reproduces <BUG-ID> based on plan.md"

# Проверяем что тест красный:
./scripts/ai-check.sh --tests-only

# T2: фикс (тест должен стать GREEN)
codex "Fix <BUG-ID> based on plan.md root cause"

# Полная проверка:
./scripts/ai-check.sh
```

---

## Stage 3: Verification

Аналогично feature-v1 Stage 4.
Дополнительно в `verification.md`:

```markdown
## Bug-specific verification
- [ ] Воспроизводящий тест был RED до фикса (подтверждено)
- [ ] Воспроизводящий тест GREEN после фикса
- [ ] Regression suite зелёный
- [ ] Root cause задокументирован
```

---

## Stage 4: Review

**Владелец:** Claude Code
**Выход:** `findings.md`

Дополнительно к стандартным findings:

```markdown
## Root cause confirmed
...

## Systemic issue?
Это единичный баг или симптом системной проблемы?

## Prevention
Что добавить в BASE.md / ai-check / тесты, чтобы этот класс багов ловился раньше?
```

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
