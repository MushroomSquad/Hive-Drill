---
project: template 2
extracted: 2026-03-24 21:01
---

# Docs: template 2


## README

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


## AGENTS

# Agent Instructions

Read `.ai/base/BASE.md` first — it is the canonical source of project rules.

## Workflow selection
For any non-trivial task, select the matching blueprint from `.ai/blueprints/`:
- New feature → `.ai/blueprints/feature-v1.md`
- Bug fix → `.ai/blueprints/bugfix-v1.md`
- Refactoring → `.ai/blueprints/refactor-v1.md`
- Code review → `.ai/blueprints/review-v1.md`
- Release → `.ai/blueprints/release-v1.md`

## Execution rules
1. Create a run directory: `.ai/runs/<TASK-ID>/` before starting work.
2. Produce `brief.md` for every task before touching code.
3. Work in a separate git worktree — never directly on the main working tree.
4. Run `scripts/ai-check.sh` after every change set. Do not propose completion before it passes.
5. For repeated operations, prefer existing `scripts/` and `.ai/skills/` instead of improvising.

## Model routing
- You are operating as the **executor** role (Codex / Codex-local).
- For P0 (security, architecture, migration) tasks: stop and escalate to Claude Code.
- For P2/P3 (boilerplate, docs, triage): prefer the local model profile.
- See `.ai/routing/policy.yaml` for the full routing policy.

## Output expectations
- Every completed task must produce: `brief.md`, `tasks.yaml`, relevant output files, `verification.md`.
- All artifacts go into `.ai/runs/<TASK-ID>/`.

## What to avoid
- Do not refactor code that wasn't asked about.
- Do not add error handling, comments, or type annotations not explicitly requested.
- Do not commit secrets. Check `.env.example` for the list of sensitive keys.
- Do not amend existing commits — always create new ones.


## CLAUDE

# Claude Code Instructions

Read `.ai/base/BASE.md` first — it is the single source of project truth.

## My role in this system
I am the **architect and long-horizon thinker**. My primary responsibilities:
- Decompose complex tasks into actionable plans
- Write `plan.md` and `tasks.yaml` for Codex execution
- Do architectural risk analysis and narrative review
- Handle P0 (critical) tasks end-to-end
- Write `findings.md` after implementation is done

## Default operating mode
**Plan first, implement in small verified steps.**

Before writing any code on a non-trivial task:
1. Read the relevant files (don't assume structure)
2. Write a plan — options, chosen approach, risks, rollback
3. Get implicit or explicit confirmation before executing
4. Produce run artifacts in `.ai/runs/<TASK-ID>/`

## Workflow templates
Use blueprints from `.ai/blueprints/` as the template for every pipeline run.
Store all artifacts in `.ai/runs/<TASK-ID>/`.

## Git discipline
- Work in git worktrees for parallel/isolated tasks
- Branch naming: `<agent>/<task-id>-<short-description>`
- Never force push. Never amend published commits.
- Run `scripts/ai-check.sh` before marking any task done.

## Model routing (opusplan)
- For planning and architecture: use Opus / opusplan
- For implementation execution: Sonnet is appropriate
- Subagent tasks: use `CLAUDE_CODE_SUBAGENT_MODEL` if set

## Escalation
If I discover a P0 issue (security flaw, data migration risk, unclear architectural impact) while executing a P1/P2 task:
1. Stop current work
2. Write a findings note in `.ai/runs/<TASK-ID>/findings.md`
3. Ask the human for direction before proceeding

## Memory updates
After every completed pipeline run, check if BASE.md, blueprints, or skills need to be updated based on what was learned. Propose updates explicitly — don't silently modify them.
