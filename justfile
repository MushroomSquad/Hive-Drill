# 🐝 Hive Drill — AI development pipeline
# Install: cargo install just  # or: brew install just / apt install just
# Run:     just <command>
# Help:    just help

set dotenv-load := true
set positional-arguments := true

# ─── Help ───────────────────────────────────────────────────────────

# Показать справку по всем командам
help:
    @./scripts/help.sh

# ─── Man & completions ──────────────────────────────────────────────

# Открыть man-страницу just
man:
    @just --man | man -l -

# Установить автодополнения для текущего шелла (bash / zsh / fish)
completions:
    #!/usr/bin/env bash
    shell="$(basename "${SHELL:-bash}")"
    case "$shell" in
      fish)
        dir="${HOME}/.config/fish/completions"
        mkdir -p "$dir"
        just --completions fish > "$dir/just.fish"
        echo "✓ Fish completions → $dir/just.fish"
        echo "  Перезапусти fish или: source $dir/just.fish"
        ;;
      zsh)
        # Ищем первый пользовательский каталог в fpath
        dir="${HOME}/.zsh/completions"
        mkdir -p "$dir"
        just --completions zsh > "$dir/_just"
        echo "✓ Zsh completions → $dir/_just"
        echo "  Добавь в ~/.zshrc (если ещё нет):"
        echo "    fpath=(~/.zsh/completions \$fpath)"
        echo "    autoload -Uz compinit && compinit"
        ;;
      bash)
        dir="${HOME}/.local/share/bash-completion/completions"
        mkdir -p "$dir"
        just --completions bash > "$dir/just"
        echo "✓ Bash completions → $dir/just"
        echo "  Перезапусти bash или: source $dir/just"
        ;;
      *)
        echo "Шелл '${shell}' не поддерживается автоматически."
        echo "Доступные варианты:"
        echo "  just --completions bash > ~/.local/share/bash-completion/completions/just"
        echo "  just --completions zsh  > ~/.zsh/completions/_just"
        echo "  just --completions fish > ~/.config/fish/completions/just.fish"
        ;;
    esac

# ─── Основной workflow ───────────────────────────────────────────────

# Создать новую задачу (brief в Obsidian, card на kanban)
new task_id:
    @./scripts/new.sh "{{task_id}}"

# Запустить полный pipeline: Brief→Plan→Tasks→Code→Tests→Review→PR
go task_id:
    @./scripts/go.sh "{{task_id}}"

# Продолжить pipeline с конкретной стадии (0=Brief, 1=Plan, 2=Tasks, 3=Code, 4=Tests, 5=Review, 6=PR)
go-from task_id stage:
    @./scripts/go.sh "{{task_id}}" --from-stage "{{stage}}"

# История чекпоинтов задачи + команды для time travel
history task_id:
    @./scripts/history.sh "{{task_id}}"

# ─── Тесты ──────────────────────────────────────────────────────────

# Запустить тесты (встроенный runner, без зависимостей)
test *suites:
    @bash tests/run_tests.sh {{suites}}

# ─── Статус ─────────────────────────────────────────────────────────

# Статус агентов, LLM, MCP, активных runs
status:
    @./scripts/status.sh

# lint + typecheck + tests + secrets (полная проверка done-критерия)
check *args:
    @./scripts/ai-check.sh {{args}}

# ─── Worktrees ──────────────────────────────────────────────────────

# Создать git worktree для задачи
wt-create task_id:
    @./scripts/worktree.sh create "{{task_id}}"

# Список активных worktrees
wt-list:
    @./scripts/worktree.sh list

# Удалить worktree задачи
wt-clean task_id:
    @./scripts/worktree.sh clean "{{task_id}}"

# ─── Локальный LLM ──────────────────────────────────────────────────

# Запустить TabbyAPI с кодер-профилем (Qwen2.5-Coder 7B)
llm-up:
    @./llm/profiles/tabbyapi-coder.sh

# Запустить TabbyAPI с writer-профилем (Qwen2.5 14B)
llm-writer:
    @./llm/profiles/tabbyapi-writer.sh

# Проверить LLM endpoint
llm-test:
    @./llm/scripts/test-endpoint.sh tabbyapi

# Cloudflare tunnel для удалённого доступа к TabbyAPI
llm-tunnel:
    @./llm/cursor/tunnel.sh tabbyapi cloudflared

# ─── Документация & Canvas ──────────────────────────────────────────

# Сгенерировать canvas-схему архитектуры активного проекта
arch:
    @./scripts/canvas-arch.sh

# Сгенерировать схему для произвольного внешнего проекта
arch-of project:
    @./scripts/canvas-arch.sh "{{project}}"

# Обновить docs/ в vault без перегенерации canvas
docs:
    @./scripts/canvas-arch.sh --docs

# ─── Workspace (целевой проект) ─────────────────────────────────────

# Клонировать внешний проект в workspace/ и прописать WORKSPACE в .env
clone url name="project":
    #!/usr/bin/env bash
    mkdir -p workspace
    git clone "{{url}}" "workspace/{{name}}"
    if [ -f .env ]; then
        if grep -q "^WORKSPACE=" .env; then
            python3 -c "
import re, sys
p='.env'
t=open(p).read()
open(p,'w').write(re.sub(r'^WORKSPACE=.*','WORKSPACE=workspace/{{name}}',t,flags=re.M))
"
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

# Открыть workspace в редакторе (\$EDITOR или code)
open:
    #!/usr/bin/env bash
    source .env 2>/dev/null || true
    TARGET="${WORKSPACE:-$(pwd)}"
    [ "${TARGET}" = "$(pwd)" ] && echo "Открываю корень roi/" || echo "Открываю: ${TARGET}"
    ${EDITOR:-code} "${TARGET}"

# ─── Проекты ────────────────────────────────────────────────────────

# Управление проектами: add / switch / list / remove / current / info
project *args:
    @./scripts/project.sh {{args}}

# ─── Self-improve ────────────────────────────────────────────────────

# Self-improve workspace: init / update / status / sync
self *args:
    @./scripts/self.sh {{args}}

# GitHub issues: Claude-анализ + fzf выбор + pipeline
issues *args:
    @./scripts/issues.sh {{args}}

# ─── Инициализация ──────────────────────────────────────────────────

# Полная инициализация системы
setup:
    @./scripts/init.sh --all

# Установить только MCP серверы
setup-mcp:
    @./scripts/init.sh --mcp

# Установить только GSD хуки
setup-gsd:
    @./scripts/init.sh --gsd
