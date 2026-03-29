# Blueprint: PR Review — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Структурированный code review PR с классификацией замечаний.

## Roles

| Стадия | Владелец |
|--------|---------|
| Context loading | Claude Code |
| Automated checks | scripts |
| Narrative review | Claude Code |
| Findings output | Claude Code |

---

## Stage 0: Context loading

**Владелец:** Claude Code
**Задача:** понять что и зачем изменяется

Читать в таком порядке:
1. PR description / `pr-body.md`
2. `brief.md` и `plan.md` из `.ai/runs/` если есть
3. Diff (не просто `git diff`, а с контекстом: `git diff --stat`, потом по файлам)
4. Тесты изменились?
5. Смежные файлы (импорты, зависимости)

---

## Stage 1: Automated checks

```bash
./scripts/ai-check.sh
```

Если красный → зафиксировать в findings как blocker.

---

## Stage 2: Narrative review

**Шаблон обхода diff:**

Для каждого изменённого модуля:
1. Корректность логики
2. Безопасность (injection, auth, secrets)
3. Производительность (N+1, неожиданные аллокации)
4. Тестовое покрытие
5. Соответствие архитектуре (BASE.md, architecture-map.md)
6. Читаемость и соглашения по коду

---

## Stage 3: Findings

**Выход:** `findings.md`

**Классификация замечаний:**

| Уровень | Когда | Требует action? |
|---------|-------|----------------|
| 🔴 **BLOCKER** | Баг, security issue, data loss risk, нарушение архитектуры | PR не мержится |
| 🟡 **SUGGESTION** | Улучшение, которое стоит сделать | Желательно исправить |
| 💬 **NIT** | Стиль, мелкая читаемость | По желанию |

```markdown
# Findings: PR-<ID>

## Overview
Краткое описание изменений и их качества.

## Automated checks
- lint: PASS / FAIL
- typecheck: PASS / FAIL
- tests: PASS / FAIL

## Issues

### 🔴 BLOCKER: <Заголовок>
**File:** `src/...` line N
**Problem:** ...
**Fix:** ...

### 🟡 SUGGESTION: <Заголовок>
**File:** `src/...`
**Why:** ...
**Option:** ...

### 💬 NIT: <Заголовок>
...

## Security assessment
- [ ] Нет hardcoded secrets
- [ ] Нет SQL injection / XSS / command injection
- [ ] Auth / authz не обходится
- [ ] Нет exposing internal data через API

## Architecture assessment
- [ ] Соответствует архитектурным constraints из BASE.md
- [ ] Нет нарушения boundaries модулей

## Verdict
APPROVED | REQUEST CHANGES | NEEDS DISCUSSION

**Reason:** ...
```

---

## Escalation triggers (→ human required)

- Любой BLOCKER уровня security
- Breaking change без migration guide
- Изменение схемы БД без review DBA
- Diff > 800 строк без очевидного плана

---

## Artifacts

```
.ai/runs/PR-<ID>/
  findings.md
```

---

## Writing standards

После написания `findings.md` — `/humanize`. См. BASE.md § Writing standards.
