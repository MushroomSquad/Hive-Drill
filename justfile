# AI Dev OS — Task Runner
# Установка: cargo install just  # или: brew install just / apt install just
# Запуск:    just <команда>
# Список:    just --list

set dotenv-load := true
set positional-arguments := true

# ─── Основной workflow ───────────────────────────────────────────────

# Создать новую задачу (откроет шаблон в Obsidian)
new task_id:
    @./scripts/new.sh "{{task_id}}"

# Запустить pipeline для задачи (всё автоматически, с гейтами)
go task_id:
    @./scripts/go.sh "{{task_id}}"

# Продолжить с конкретной стадии
go-from task_id stage:
    @./scripts/go.sh "{{task_id}}" --from-stage "{{stage}}"

# ─── Статус ─────────────────────────────────────────────────────────
status:
    @./scripts/status.sh

check *args:
    @./scripts/ai-check.sh {{args}}

# ─── Worktrees ──────────────────────────────────────────────────────
wt-create task_id:
    @./scripts/worktree.sh create "{{task_id}}"

wt-list:
    @./scripts/worktree.sh list

wt-clean task_id:
    @./scripts/worktree.sh clean "{{task_id}}"

# ─── Локальный LLM ──────────────────────────────────────────────────
llm-up:
    @./llm/profiles/tabbyapi-coder.sh

llm-writer:
    @./llm/profiles/tabbyapi-writer.sh

llm-test:
    @./llm/scripts/test-endpoint.sh tabbyapi

llm-tunnel:
    @./llm/cursor/tunnel.sh tabbyapi cloudflared

# ─── Инициализация ──────────────────────────────────────────────────
setup:
    @./scripts/init.sh --all

setup-mcp:
    @./scripts/init.sh --mcp
