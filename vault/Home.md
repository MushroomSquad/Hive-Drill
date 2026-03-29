# 🐝 Hive Drill — Home

## Доски

- [[canvas/project-board|Project Board — Kanban задач]]
- [[canvas/pipeline-flow|Pipeline Flow — 7 стадий]]
- [[canvas/architecture|Architecture — Схема системы]]
- [[canvas/project-arch|Project Arch — Схема текущего проекта]] *(генерируется: `just arch`)*

---

## Активные задачи

```dataview
TABLE task_id, status, priority, owner
FROM "01-active"
WHERE file.name != "README"
SORT priority ASC
```

---

## Команды

**Проекты**

| Команда | Что делает |
|---|---|
| `just project add <name> <path>` | Зарегистрировать проект |
| `just project switch <name>` | Переключиться на проект |
| `just project list` | Список всех проектов |
| `just project current` | Активный проект |
| `just project info` | Детали активного проекта |

**Pipeline**

| Команда | Что делает |
|---|---|
| `just new TASK-ID` | Создать новую задачу (brief в inbox активного проекта) |
| `just go TASK-ID` | Запустить полный pipeline |
| `just go-from TASK-ID STAGE` | Продолжить с нужной стадии |
| `just status` | Показать статус системы и активного проекта |
| `just wt-list` | Список git worktrees |
| `just arch` | Сгенерировать canvas-схему текущего проекта |
| `just arch-of /path` | Сгенерировать схему внешнего проекта |
| `just docs` | Обновить документацию в vault/docs/ |

---

## Как работать

1. **Создай задачу** — `just new FEAT-001` — откроется файл-шаблон в `00-inbox/`
2. **Заполни brief** — опиши цель, скоуп, критерии приёмки
3. **Смени статус** — `status: draft` → `status: ready` в frontmatter
4. **Запусти pipeline** — `just go FEAT-001` — система пройдёт все стадии сама
5. **Одобряй гейты** — на стадиях Plan и Review система остановится и покажет артефакт: `y` чтобы продолжить, `e` чтобы отредактировать, `n` чтобы прервать

---

## Стадии pipeline

| # | Стадия | Агент | Гейт |
|---|---|---|---|
| 0 | Brief | Human | — |
| 1 | Plan | Claude | ⏸ Human approve |
| 2 | Tasks | Claude | — |
| 3 | Code | Codex | — |
| 4 | Tests | Scripts | — |
| 5 | Review | Claude | ⏸ Human approve |
| 6 | PR | Scripts | — |

---

*Vault: `vault/projects/<active>/` · Runs: `.ai/runs/<active>/` · Blueprints: `.ai/blueprints/`*
