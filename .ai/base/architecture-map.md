# Architecture Map

Карта системы для агентов — что где живёт и как связано.
Обновляй при добавлении новых модулей или изменении границ.

---

## System overview

```
┌────────────────────────────────────────────────────────────────┐
│  UI-слой         Cursor / редактор  +  Obsidian vault          │
├────────────────────────────────────────────────────────────────┤
│  Orchestration   scripts/go.sh — 7-стадийный pipeline runner   │
├────────────────────────────────────────────────────────────────┤
│  Агенты          Claude Code (архитект) | Codex (исполнитель)  │
├────────────────────────────────────────────────────────────────┤
│  Tool-bus        MCP (GitHub, Linear, Postgres, Browser...)    │
├────────────────────────────────────────────────────────────────┤
│  Blueprints      .ai/blueprints/ + .ai/skills/                 │
├────────────────────────────────────────────────────────────────┤
│  Local LLM       llm/ — Harbor + TabbyAPI + llama.cpp          │
└────────────────────────────────────────────────────────────────┘
```

---

## Modules

| Модуль | Путь | Ответственность | Агент не трогает без плана |
|--------|------|----------------|--------------------------|
| Pipeline runner | `scripts/go.sh` | 7 стадий: Brief→Plan→Tasks→Code→Tests→Review→PR | структура стадий |
| Task creator | `scripts/new.sh` | Создание brief + canvas-карточки | — |
| Project manager | `scripts/project.sh` | Регистрация проектов, переключение контекста | — |
| Quality gate | `scripts/ai-check.sh` | lint + typecheck + tests + secrets | критерии done |
| Human gate | `scripts/gate.sh` | Интерактивное y/n/e одобрение артефактов | логика одобрения |
| Canvas | `scripts/canvas-{add,move,arch}.sh` | Obsidian Canvas JSON: канбан + архитектурные схемы | формат JSON |
| Worktree manager | `scripts/worktree.sh` | git worktree: create/list/clean | naming convention |
| PR packager | `scripts/package-pr.sh` | Сборка pr-body.md для PR | формат артефакта |
| Vault | `vault/projects/<name>/` | Obsidian workspace per project: inbox/active/done/canvas. Активный проект обязателен | структура папок |
| Blueprints | `.ai/blueprints/` | Шаблоны pipeline по типам задач | frontmatter schema |
| Project registry | `.ai/projects/` | JSON-реестр проектов, коммитится | формат .json |
| Project state | `.ai/state/current` | Активный проект (локальное, не коммитится) | — |
| Runs | `.ai/runs/<project>/<id>/` | Все артефакты прогона (brief, plan, tasks, findings...) | имена файлов |
| Local LLM | `llm/` | Harbor + TabbyAPI profiles + llama.cpp fallback | профили моделей |
| MCP | `mcp/` | Конфигурация MCP серверов для агентов | config.json |

---

## Data flows

```
[Human] → brief.md (vault/projects/<p>/00-inbox/)
  → go.sh Stage 0: locate brief, validate frontmatter
    → Stage 1: Claude Code → plan.md                 [Gate]
      → Stage 2: Claude Code → tasks.md
        → Stage 3: Codex в worktree → code changes
          → Stage 4: ai-check.sh → test-report.md
            → Stage 5: Claude Code → findings.md     [Gate]
              → Stage 6: package-pr.sh → pr-body.md
                → canvas-move.sh: карточка → done
```

**Хранение артефактов:**
`go.sh` пишет все промежуточные файлы в `.ai/runs/<project>/<TASK-ID>/`.
`vault/projects/<name>/01-active/` — brief пока задача активна.
`vault/projects/<name>/02-done/` — brief после завершения.

---

## External dependencies

| Сервис | Назначение | Критичность |
|--------|-----------|------------|
| Claude Code CLI | Архитектурный агент (stages 1, 2, 5) | критичная |
| Codex CLI | Исполнитель кода (stage 3) | высокая |
| TabbyAPI / llama.cpp | Локальный LLM для P2/P3 задач | средняя (деградирует до cloud) |
| Harbor | Управление LLM-сервисами | низкая (обёртка над TabbyAPI) |
| MCP servers | GitHub, Linear, Postgres и др. | зависит от задачи |

---

## Known tech debt

| Проблема | Где | Приоритет | Когда трогать |
|----------|-----|-----------|--------------|
| `architecture-map.md` генерируется `canvas-arch.sh` неполно | `scripts/canvas-arch.sh` | P3 | при рефакторе canvas |
| `vault/docs/roi.md` — автогенерация, может устаревать | `just docs` | P3 | при обновлении arch-скрипта |
| YAML-пайплайны в `.ai/pipelines/` пока не подключены к go.sh | `.ai/pipelines/` | P2 | при добавлении CI-интеграции |

---

## Zones agents must not touch

- `.ai/base/BASE.md` — изменяет только человек
- `scripts/go.sh` стадии 0-6 — структура требует явного решения
- `vault/templates/brief.md` — формат frontmatter (task_id, status, verdict)
- `.ai/runs/<project>/<id>/` имена файлов — контракт между агентами
- `scripts/ai-check.sh` exit codes — публичный API done-критерия
