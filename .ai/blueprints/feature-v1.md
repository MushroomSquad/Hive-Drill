# Blueprint: Feature — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Реализация новой функциональности от brief'а до готового PR.

## Roles

| Стадия | Владелец | Инструмент |
|--------|---------|-----------|
| Intake | Human / Cursor | — |
| Architectural pass | Claude Code | opus / opusplan |
| Task slicing | Claude Code | sonnet |
| Execution | Codex | cloud-medium или local-fast |
| Verification | scripts | ai-check.sh |
| Narrative review | Claude Code | sonnet |
| PR packaging | Codex / Cursor | cloud-medium |
| Retro | Human + agent | — |

---

## Stage 0: Intake

**Владелец:** Human / Cursor
**Вход:** запрос (issue, комментарий, задача)
**Выход:** `brief.md`

`brief.md` должен содержать:
```markdown
# Brief: <TASK-ID> — <Название>

## Goal
Что нужно сделать и зачем.

## Scope
### In scope
- ...
### Out of scope
- ...

## Constraints
- Нельзя трогать: ...
- Дедлайн: ...
- Зависит от: ...

## Affected modules
- ...

## Risks
- ...

## Acceptance criteria
- [ ] ...
- [ ] ...
```

**Criteria to proceed:** brief.md заполнен и все поля непусты.

---

## Stage 1: Architectural pass

**Владелец:** Claude Code
**Вход:** `brief.md`, доступ к codebase
**Выход:** `plan.md`

Задачи:
1. Прочитать релевантные файлы кодовой базы
2. Оценить варианты реализации (минимум 2)
3. Выбрать вариант и обосновать
4. Выписать риски и rollback стратегию

`plan.md` структура:
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
Option X, потому что...

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

Параллельно с `plan.md` веди `decisions.md` — записывай каждое нетривиальное архитектурное решение по шаблону.

**Humanizer**: после написания `plan.md` — `/humanize .ai/runs/<TASK-ID>/plan.md`

**Criteria to proceed:** plan.md утверждён (явно или через timeout без возражений).

---

## Stage 2: Task slicing

**Владелец:** Claude Code / Cursor
**Вход:** `plan.md`
**Выход:** `tasks.yaml`

```yaml
run_id: <TASK-ID>
blueprint: feature-v1
tasks:
  - id: T1
    title: <атомарная задача>
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

**Правила нарезки:**
- Каждая задача = один осмысленный коммит
- P0 задачи не могут быть у Codex без проверки Claude
- Задачи с `model_lane: local` должны подходить для P2/P3

**Criteria to proceed:** tasks.yaml утверждён, все T* атомарны.

---

## Stage 3: Isolated execution

**Владелец:** Codex (P1/P2) или Claude Code (P0)
**Вход:** `tasks.yaml`, код
**Выход:** изменения в worktree

```bash
# Создать worktree для задачи
./scripts/worktree.sh create <TASK-ID>

# Выполнить задачи Codex
codex --profile cloud-medium "Execute T1: <описание>"

# Проверка после каждой задачи
./scripts/ai-check.sh
```

**Правила:**
- Каждый агент работает в своём worktree
- Не смешивать несколько T* в одном коммите без явной зависимости
- Если `ai-check.sh` красный — стоп, не продолжать

---

## Stage 4: Verification

**Владелец:** scripts
**Вход:** изменения в worktree
**Выход:** `verification.md`

```bash
./scripts/ai-check.sh 2>&1 | tee .ai/runs/<TASK-ID>/verification.md
```

`verification.md` структура:
```markdown
# Verification: <TASK-ID>

## Check results
- lint: PASS / FAIL
- typecheck: PASS / FAIL
- tests: PASS / FAIL (N passed, M failed)

## Manual verification
- [ ] feature работает как описано в brief.md
- [ ] acceptance criteria выполнены

## Notes
...
```

**Criteria to proceed:** все проверки PASS, acceptance criteria checklist заполнен.

---

## Stage 5: Narrative review

**Владелец:** Claude Code
**Вход:** diff, `plan.md`, `verification.md`
**Выход:** `findings.md`

```markdown
# Findings: <TASK-ID>

## Architecture assessment
Не нарушена ли архитектура? Нет ли неожиданной сложности?

## Technical debt introduced
- ...

## Security notes
- ...

## Follow-up tasks
- [ ] ...

## Verdict
APPROVED / NEEDS CHANGES / BLOCKED (reason)
```

**Humanizer**: после написания `findings.md` — `/humanize .ai/runs/<TASK-ID>/findings.md`

**Criteria to proceed:** verdict = APPROVED.

---

## Stage 6: PR packaging

**Владелец:** Codex / Cursor
**Вход:** diff, `brief.md`, `findings.md`
**Выход:** `pr-body.md`, commit message

```markdown
# pr-body.md

## Summary
1-3 bullet points: что сделано и зачем.

## Changes
- `src/...`: что изменилось
- `tests/...`: что покрыто

## Test plan
- [ ] Запустил ai-check.sh — зелёный
- [ ] Проверил acceptance criteria из brief.md
- [ ] Нет regression в смежных модулях

## Notes
...
```

**Humanizer**: после написания `pr-body.md` — `/humanize .ai/runs/<TASK-ID>/pr-body.md`

---

## Stage 7: Retro

**Владелец:** Human + Claude Code
**Задача:** обновить систему на основе уроков

Чеклист:
- [ ] Нужно ли обновить BASE.md?
- [ ] Нужно ли обновить этот blueprint?
- [ ] Появились ли новые паттерны, достойные Skill?
- [ ] Что пошло не так и почему?

---

## Artifacts checklist

```
.ai/runs/<TASK-ID>/
  brief.md        ✅ Stage 0
  plan.md         ✅ Stage 1
  decisions.md    ✅ Stage 1  (обновляй при каждом нетривиальном решении)
  tasks.yaml      ✅ Stage 2
  checkpoint.yml  ✅ каждый Stage (авто)
  verification.md ✅ Stage 4
  findings.md     ✅ Stage 5
  pr-body.md      ✅ Stage 6
  retro.md        ✅ Stage 7 (опционально)
```
