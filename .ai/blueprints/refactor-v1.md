# Blueprint: Refactor — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Изменение структуры кода без изменения поведения.

**Золотое правило:** поведение до = поведение после. Тесты до = тесты после.
Рефакторинг без тестов — это просто изменение кода.

## Roles

| Стадия | Владелец |
|--------|---------|
| Scope definition | Claude Code |
| Safety net check | Codex / scripts |
| Execution | Codex (по шагам) |
| Verification | scripts |
| Architecture review | Claude Code |

---

## Stage 0: Scope definition

**Выход:** `brief.md`

```markdown
# Brief: <TASK-ID> — Refactor: <описание>

## Motivation
Почему нужен рефактор (tech debt, читаемость, производительность, coupling).

## Scope
### Что меняем
- ...
### Что НЕ меняем (поведение)
- ...
### Out of scope
- ...

## Success metric
Как измеримо улучшится ситуация после рефактора?
(метрика сложности, покрытие, время сборки, etc.)

## Risks
- Регрессии: ...
- Объём diff: ожидаемый ~N строк
```

**СТОП если:**
- Scope не определён чётко
- Нет тестов для изменяемого кода (нужно сначала добавить)
- Ожидаемый diff > 1000 строк (разбить на несколько задач)

---

## Stage 1: Safety net

**Владелец:** Codex / scripts
**Задача:** убедиться, что тесты покрывают изменяемый код

```bash
# Покрытие до рефактора (зафиксировать)
./scripts/ai-check.sh --coverage > .ai/runs/<TASK-ID>/coverage-before.txt

# Если покрытие < threshold → сначала добавить тесты
```

---

## Stage 2: Incremental execution

**Правило:** рефактор делается шагами. Каждый шаг должен быть атомарным и верифицируемым.

Типовые шаги (выбирать нужные):
1. Extract method / function
2. Rename (с поиском всех использований)
3. Move to module
4. Split class / file
5. Simplify condition
6. Remove duplication (DRY)
7. Replace pattern

```bash
# После каждого шага:
./scripts/ai-check.sh
git add -p && git commit -m "refactor: <описание шага>"
```

---

## Stage 3: Verification

Дополнительно к стандартному:

```markdown
## Refactor-specific verification
- [ ] Все тесты проходят (никакие не удалены)
- [ ] Поведение не изменилось (acceptance test / smoke test)
- [ ] Метрика улучшилась: <до> → <после>
- [ ] Нет новых TODO без TICKET-ID
```

---

## Stage 4: Architecture review

**Выход:** `findings.md` с оценкой улучшений

```markdown
## Improvement assessment
До: ...
После: ...

## Была ли достигнута цель рефактора?

## Новые риски?

## Рекомендации по следующим шагам
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
