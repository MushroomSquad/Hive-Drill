# AI Dev OS

Производственная система разработки с AI: Cursor + Warp + Codex + Claude Code + локальный LLM стек.

Не набор инструментов, а **фабрика повторяемой разработки** с blueprint-пайплайнами, роутингом задач по приоритету и постоянной памятью проекта.

---

## Архитектура системы

```
┌─────────────────────────────────────────────────────────────┐
│  UI-слой          Cursor (редактор, ревью, ручная коррекция) │
├─────────────────────────────────────────────────────────────┤
│  Orchestration    Warp / Oz (терминал, pipeline runner, CI)  │
├─────────────────────────────────────────────────────────────┤
│  Агенты           Claude Code (архитект) │ Codex (исполнитель)│
├─────────────────────────────────────────────────────────────┤
│  Tool-bus         MCP (GitHub, Linear, Postgres, Browser...) │
├─────────────────────────────────────────────────────────────┤
│  Blueprints       .ai/ (пайплайны, скиллы, память, ранзы)   │
├─────────────────────────────────────────────────────────────┤
│  Local LLM        llm/ (Harbor + TabbyAPI + llama.cpp)       │
└─────────────────────────────────────────────────────────────┘
```

## Роли агентов

| Агент | Роль | Приоритеты |
|-------|------|-----------|
| **Claude Code** | Архитектор, длинный мыслитель | P0: critical, P1: plan+review |
| **Codex** | Исполнитель, быстрый инженер | P1: implementation, P2: routine |
| **Cursor** | Кабина пилота, ревью, ручная коррекция | все |
| **Warp/Oz** | Диспетчерская, pipeline runner | all automation |
| **Local LLM** | Локальный backend для P2/P3 задач | P2: routine, P3: background |

## Маршрутизация задач

| Приоритет | Тип задачи | Агент | Модель |
|-----------|-----------|-------|--------|
| **P0** critical | security, migration, architecture | Claude Code | opus/opusplan |
| **P1** standard | feature, refactor, integration | Claude Sonnet + Codex cloud | cloud-medium |
| **P2** routine | boilerplate, docs, simple tests | Codex local | local-fast |
| **P3** background | triage, changelogs, search | Codex local | local-cheap |

## Структура проекта

```
.ai/
  base/          — канон: правила, архитектура, критерии done
  blueprints/    — шаблоны пайплайнов (feature, bugfix, refactor...)
  skills/        — переиспользуемые micro-workflow
  pipelines/     — YAML-пайплайны для Oz/CI
  routing/       — policy маршрутизации задач
  runs/          — артефакты каждого прогона
  evals/         — золотые тесты для blueprint'ов
.codex/          — config.toml (cloud + local профили)
.cursor/rules/   — editor-specific правила
.claude/         — settings, skills Claude Code
mcp/             — конфигурация MCP серверов
scripts/         — ai-check, blueprint-run, plan-init, package-pr
llm/             — локальный LLM стек (Harbor + TabbyAPI + llama.cpp)
```

## Быстрый старт

### 1. Инициализация системы

```bash
./scripts/init.sh
```

Скрипт: проверит зависимости, скопирует `.env.example` → `.env`, настроит MCP, проверит локальный LLM стек.

### 2. Запустить локальный LLM

```bash
just llm-up              # TabbyAPI + кодер 7B
# или
./llm/setup/install.sh   # первая установка
```

### 3. Запустить blueprint-пайплайн

```bash
# Новая фича
just bp feature TASK-123

# Баг-фикс
just bp bugfix BUG-456

# Code review
just bp review PR-789
```

### 4. Проверить статус

```bash
just status              # все агенты и сервисы
./scripts/ai-check.sh    # валидация проекта
```

## Жизненный цикл pipeline

```
Intake (brief.md)
  → Architectural pass — Claude Code (plan.md)
    → Task slicing — Claude / Cursor (tasks.yaml)
      → Isolated execution — Codex в worktree (код)
        → Verification — scripts/ai-check.sh (verification.md)
          → Narrative review — Claude Code (findings.md)
            → PR packaging — Codex/Cursor (pr-body.md)
              → Retro → обновление BASE.md / blueprints
```

## Локальный LLM

Подробнее: [llm/README.md](llm/README.md)

RTX 4070 (12 GB VRAM) — рекомендуемый стек: Harbor + TabbyAPI + EXL2.

```bash
cd llm
./setup/install.sh
./models/download-coder.sh
./profiles/tabbyapi-coder.sh
```
