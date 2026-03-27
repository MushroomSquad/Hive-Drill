# BASE — Канон проекта

Этот файл — единственный источник истины о правилах проекта.
`AGENTS.md` и `CLAUDE.md` ссылаются на него. Не дублируй правила из BASE.md в других файлах.

---

## Project mission

**AI Dev OS** — производственная система разработки с AI.
Не набор инструментов, а **фабрика повторяемой разработки** с blueprint-пайплайнами, роутингом задач по приоритету и постоянной памятью проекта.

Система преобразует идею задачи в готовый PR через 7 автоматизированных стадий, использует несколько AI-агентов в изолированных git worktrees и управляет знаниями через Obsidian vault.

**Целевая аудитория**: инженеры-одиночки и небольшие команды, которые хотят ускорить разработку с AI без потери контроля.

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
| `scripts/ai-check.sh` | Единый критерий done: lint + typecheck + tests + secrets |
| `scripts/gate.sh` | Интерактивное одобрение артефактов |
| `vault/` | Obsidian workspace: briefs, активные задачи, канбан |
| `.ai/runs/<ID>/` | Все артефакты конкретного прогона |
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
