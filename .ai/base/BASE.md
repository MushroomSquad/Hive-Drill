# BASE — Project Canon

This file is the single source of truth for project rules.
`AGENTS.md` and `CLAUDE.md` reference it. Do not duplicate rules from BASE.md elsewhere.

---

## Project mission

**Hive Drill** — a self-improving AI development pipeline. A fun side project built entirely
by neural networks: designed, coded, tested, and maintained by AI agents.

Not a toolbox — a **repeatable development factory** with blueprint pipelines, priority-based
task routing, and persistent project memory. The system turns a task idea into a merged PR
through 7 automated stages, using multiple AI agents in isolated git worktrees, with knowledge
managed through an Obsidian vault.

One instance of Hive Drill can work on another instance of itself — picking up GitHub issues,
running the pipeline, and pushing improvements back in a closed loop.

**Target audience**: solo engineers and small teams who want to accelerate AI-assisted
development without losing control. And anyone curious how far a self-directed AI swarm can go.

---

*Русский: **Hive Drill** — самосовершенствующийся AI-пайплайн разработки. Фановый проект,
полностью сделанный нейронками: спроектирован, написан, протестирован и поддерживается
AI-агентами. Один инстанс дорабатывает другой, пушит изменения, пулит себя — по кругу.*

---

## Architecture constraints

**Уже принято, не пересматривается:**

- Архитектура: 3-слойная (UI → Orchestration → Agents → Tool-bus → Blueprints)
- Pipeline состоит ровно из 7 стадий (0-6); добавление новых стадий — P0 решение
- Vault — это Obsidian-совместимый Markdown, не кастомный формат
- Canvas — JSON-формат Obsidian Canvas (nodes/edges), не другой формат
- Агенты изолированы через git worktrees (один worktree на агента на задачу)
- Gate (ворота одобрения) — обязательные на стадиях 1 и 5; нельзя пропускать без явного флага

**Границы зон ответственности:**

| Компонент | Отвечает за |
|-----------|------------|
| `scripts/go.sh` | Оркестрация pipeline (7 стадий) |
| `scripts/new.sh` | Создание задачи (brief + канбан) |
| `scripts/project.sh` | Управление проектами (add/switch/list/remove) |
| `scripts/ai-check.sh` | Единый критерий done: lint + typecheck + tests + secrets |
| `scripts/gate.sh` | Интерактивное одобрение артефактов |
| `vault/projects/<name>/` | Изолированный Obsidian workspace для проекта |
| `.ai/runs/<project>/<ID>/` | Все артефакты конкретного прогона |
| `.ai/projects/<name>.json` | Реестр проектов (коммитится) |
| `.ai/state/current` | Активный проект (локальное, не коммитится) |
| `.ai/blueprints/` | Шаблоны pipeline (feature, bugfix, refactor, review, release) |
| `llm/` | Локальный LLM стек (Harbor + TabbyAPI) |
| `mcp/` | Конфигурация MCP серверов |

**Что нельзя трогать без явного решения:**
- Формат frontmatter в артефактах (task_id, status, verdict — обязательные поля)
- Структура `.ai/runs/<ID>/` (имена файлов — часть контракта между агентами)
- Git дисциплина: worktrees, branch naming `agent/<TASK-ID>-<agent>`

---

## Tech stack

| Компонент | Технология | Версия |
|-----------|------------|--------|
| Pipeline runner | Bash | 5.x |
| Task runner | [just](https://just.systems) | 1.x |
| AI агенты | Claude Code CLI, Codex CLI | актуальные |
| Local LLM | Harbor + TabbyAPI + llama.cpp | актуальные |
| Kanban / docs | Obsidian (Markdown + Canvas JSON) | актуальные |
| Canvas management | Python 3 (stdlib only) | 3.10+ |
| MCP servers | Node.js / npx | LTS |
| Claude Code hooks | GSD (get-shit-done) v1.30+ | глобально |

---

## Build & test commands

```bash
# Запустить все тесты
bash tests/run_tests.sh

# Запустить конкретный тест
bash tests/run_tests.sh gate canvas

# Валидация проекта (lint + typecheck + tests + secrets)
./scripts/ai-check.sh              # полная проверка
./scripts/ai-check.sh --quick      # только lint
./scripts/ai-check.sh --tests-only # только тесты

# Полный pipeline для задачи
just go TASK-ID

# Инициализация
./scripts/init.sh --all

# Статус системы
just status
```

---

## Coding standards

- **Язык нового кода**: Bash (скрипты) + Python 3 (только stdlib, только для канваса)
- **Именование**: UPPER_CASE для констант, lower_case для локальных переменных в Bash
- **Все скрипты**: `set -euo pipefail` в начале
- **Minимальное покрытие тестами**: каждая публичная функция скрипта + happy path + error path
- **Тесты**: `tests/run_tests.sh` — встроенный test runner без внешних зависимостей
- **Форматтер**: нет (bash — вручную, придерживаться стиля существующих скриптов)
- **Secrets**: никогда не хардкодить, только через `.env` (проверяется в `ai-check.sh`)

---

## Writing standards (humanizer)

**Обязательно** для всех текстовых артефактов, которые создаёт этот проект:

- Все `.md` документы pipeline (`plan.md`, `findings.md`, `pr-body.md`, `brief.md`, `tasks.md`)
- Комментарии в коде, которые пишет агент
- README и любая другая документация

**Правило**: после написания любого документа или блока комментариев — пропусти через `/humanize` (GSD skill `humanizer`).

```bash
# После создания артефакта:
/humanize .ai/runs/<TASK-ID>/plan.md
/humanize .ai/runs/<TASK-ID>/findings.md
/humanize .ai/runs/<TASK-ID>/pr-body.md
```

**Зачем**: AI-генерированные тексты содержат характерные паттерны (inflated significance, AI vocabulary, em dash overuse и др.). Humanizer их убирает и добавляет живой голос.

**Когда НЕ применять**: frontmatter полей (task_id, status, verdict) — их не трогать.

---

## GSD (get-shit-done) integration

[GSD](https://github.com/gsd-build/get-shit-done) установлен **глобально** (`~/.claude/hooks/`).
Автоматически активен для всех сессий Claude Code в этом проекте.

**Что GSD добавляет к этому проекту:**

| Hook | Когда | Что делает |
|------|-------|------------|
| `gsd-context-monitor.js` | После каждого tool use | Предупреждает агента когда контекст < 35% / 25% |
| `gsd-prompt-guard.js` | Перед Write/Edit в `.planning/` | Сканирует на prompt injection паттерны |
| `gsd-statusline.js` | Всегда (statusline) | Показывает модель, контекст, директорию |
| `gsd-check-update.js` | При старте сессии | Проверяет обновления GSD |

**Для проекта**: GSD работает прозрачно. Дополнительной конфигурации не требует.
Если хочешь использовать GSD workflow (`.planning/` директорию), добавь `.planning/` в `.gitignore`.

---

## What agents may NOT do without explicit approval

- Изменять схему frontmatter артефактов (task_id, status, verdict)
- Менять публичный API скриптов (сигнатуры, exit codes, имена файлов)
- Удалять данные в production vault
- Изменять CI/CD пайплайны
- Коммитить secrets, ключи, credentials
- Amend опубликованных коммитов
- Изменять `BASE.md` (требует ревью человека, не агента)

---

## Definition of done

Задача считается выполненной, когда:
- [ ] `bash tests/run_tests.sh` проходит без ошибок
- [ ] `./scripts/ai-check.sh` проходит без FAIL
- [ ] Юнит-тесты написаны / обновлены для изменённых скриптов
- [ ] `verification.md` заполнен в `.ai/runs/<TASK-ID>/`
- [ ] `pr-body.md` готов
- [ ] Нет закомментированного кода
- [ ] Нет hardcoded secrets

---

## Review rules

1. Каждый PR должен иметь `pr-body.md` с мотивацией изменений.
2. Breaking changes требуют явного обозначения в PR.
3. Изменения в `.ai/base/BASE.md` требуют ревью человека, не агента.

---

## Escalation policy

| Ситуация | Действие |
|---------|---------|
| Security issue найден | Стоп, создать findings.md, эскалировать |
| Неясная причина бага | Стоп, написать диагноз, спросить человека |
| Требуется изменить схему артефактов | Стоп, написать migration plan, спросить |
| Diff > 500 строк неожиданно | Проверить scope, возможно нужно разбить |
