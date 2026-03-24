# AI Dev OS — Task Runner
# Установка: cargo install just  # или: brew install just / apt install just
# Запуск:    just <команда>
# Список:    just --list

# Переменные по умолчанию
set dotenv-load := true
set positional-arguments := true

# ─── Статус и проверки ──────────────────────────────────────────────────

# Показать статус всей системы
status:
    @./scripts/status.sh

# Запустить валидационный шлюз
check *args:
    @./scripts/ai-check.sh {{args}}

# Быстрая проверка (lint only)
lint:
    @./scripts/ai-check.sh --quick

# ─── Blueprint пайплайны ────────────────────────────────────────────────

# Запустить blueprint-пайплайн: just bp <type> <TASK-ID> [stage]
# Типы: feature, bugfix, refactor, review, release
bp type task_id stage="all":
    @./scripts/blueprint-run.sh "{{type}}" "{{task_id}}" "{{stage}}"

# Инициализировать новый run (только структура, без запуска агентов)
init-run task_id blueprint="feature":
    @./scripts/plan-init.sh "{{task_id}}" "{{blueprint}}"

# Упаковать PR из артефактов run'а
pr task_id:
    @./scripts/package-pr.sh "{{task_id}}"

# Показать артефакты run'а
run-show task_id:
    @ls -la .ai/runs/{{task_id}}/ 2>/dev/null || echo "Run не найден: {{task_id}}"

# Список всех runs
runs:
    @find .ai/runs -maxdepth 1 -mindepth 1 -type d | sort -r | \
     xargs -I{} sh -c 'echo "  $(basename {})  ($(ls {} | wc -l) files)"' 2>/dev/null || \
     echo "Нет runs"

# ─── Git worktrees ──────────────────────────────────────────────────────

# Создать worktrees для задачи (claude + codex)
wt-create task_id:
    @./scripts/worktree.sh create "{{task_id}}"

# Список worktrees
wt-list:
    @./scripts/worktree.sh list

# Удалить worktrees задачи
wt-clean task_id:
    @./scripts/worktree.sh clean "{{task_id}}"

# ─── Локальный LLM стек ─────────────────────────────────────────────────

# Поднять TabbyAPI с кодером 7B
llm-up:
    @./llm/profiles/tabbyapi-coder.sh

# Поднять писателя 14B
llm-writer:
    @./llm/profiles/tabbyapi-writer.sh

# Поднять llama.cpp router
llm-llamacpp:
    @./llm/profiles/llamacpp-router.sh

# Переключить локальную модель: just llm-switch <profile>
# Профили: coder, writer, llamacpp, airllm
llm-switch profile:
    @./llm/scripts/switch-model.sh "{{profile}}"

# Тест локального endpoint
llm-test target="tabbyapi":
    @./llm/scripts/test-endpoint.sh "{{target}}"

# Бенчмарк локальной модели
llm-bench target="tabbyapi" mode="short":
    @./llm/scripts/benchmark.sh "{{target}}" "{{mode}}"

# Статус локального LLM
llm-status:
    @./llm/scripts/status.sh

# Скачать основной кодер (Qwen2.5-Coder-7B EXL2)
llm-download-coder:
    @./llm/models/download-coder.sh

# Скачать писателя (Qwen2.5-14B EXL2)
llm-download-writer:
    @./llm/models/download-writer.sh

# HTTPS туннель для Cursor
llm-tunnel backend="tabbyapi" tunnel="cloudflared":
    @./llm/cursor/tunnel.sh "{{backend}}" "{{tunnel}}"

# ─── Инициализация ──────────────────────────────────────────────────────

# Полная инициализация проекта
setup:
    @./scripts/init.sh --all

# Только MCP серверы
setup-mcp:
    @./scripts/init.sh --mcp

# Только локальный LLM
setup-llm:
    @./scripts/init.sh --llm

# ─── Ярлыки для частых операций ─────────────────────────────────────────

# Быстрый code review текущего diff
review:
    @TASK_ID="PR-$(date +%Y%m%d-%H%M)" && \
     mkdir -p .ai/runs/$TASK_ID && \
     ./scripts/blueprint-run.sh review $TASK_ID

# Открыть базу знаний проекта
base:
    @${EDITOR:-cat} .ai/base/BASE.md

# Открыть архитектурную карту
arch:
    @${EDITOR:-cat} .ai/base/architecture-map.md
