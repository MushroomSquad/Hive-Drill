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

# ─── Тесты ──────────────────────────────────────────────────────────

# Запустить все тесты (встроенный runner, без зависимостей)
test *suites:
    @bash tests/run_tests.sh {{suites}}

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

# ─── Документация & Canvas ──────────────────────────────────────────

# Сгенерировать canvas-схему архитектуры текущего проекта
arch:
    @./scripts/canvas-arch.sh

# Сгенерировать схему для внешнего проекта
arch-of project:
    @./scripts/canvas-arch.sh "{{project}}"

# Обновить только docs/ в vault (без canvas)
docs:
    @./scripts/canvas-arch.sh --docs

# ─── Workspace (целевой проект) ─────────────────────────────────────

# Клонировать проект в workspace/ и прописать WORKSPACE в .env
clone url name="project":
    #!/usr/bin/env bash
    mkdir -p workspace
    git clone "{{url}}" "workspace/{{name}}"
    if [ -f .env ]; then
        if grep -q "^WORKSPACE=" .env; then
            sed -i "s|^WORKSPACE=.*|WORKSPACE=workspace/{{name}}|" .env
        else
            echo "WORKSPACE=workspace/{{name}}" >> .env
        fi
    else
        echo "WORKSPACE=workspace/{{name}}" > .env
    fi
    echo "✓ Клонировано: workspace/{{name}}"
    echo "  WORKSPACE=workspace/{{name}} записан в .env"

# Показать текущий workspace и его статус
workspace:
    #!/usr/bin/env bash
    source .env 2>/dev/null || true
    if [ -z "${WORKSPACE:-}" ]; then
        echo "WORKSPACE не задан — агенты работают в корне roi/"
        echo "Клонируй проект: just clone <url> <name>"
    elif [ -d "${WORKSPACE}" ]; then
        echo "Workspace: ${WORKSPACE}"
        echo "Последние коммиты:"
        git -C "${WORKSPACE}" log --oneline -5 2>/dev/null || true
    else
        echo "WORKSPACE=${WORKSPACE} (директория не найдена)"
        echo "Клонируй: just clone <url> $(basename ${WORKSPACE})"
    fi

# Открыть workspace в редакторе (EDITOR или code)
open:
    #!/usr/bin/env bash
    source .env 2>/dev/null || true
    TARGET="${WORKSPACE:-$(pwd)}"
    [ "${TARGET}" = "$(pwd)" ] && echo "Открываю корень roi/" || echo "Открываю: ${TARGET}"
    ${EDITOR:-code} "${TARGET}"

# ─── Инициализация ──────────────────────────────────────────────────
setup:
    @./scripts/init.sh --all

setup-mcp:
    @./scripts/init.sh --mcp

setup-gsd:
    @./scripts/init.sh --gsd
