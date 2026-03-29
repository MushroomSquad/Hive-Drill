#!/usr/bin/env bash
# help.sh — справка по всем командам AI Dev OS
set -euo pipefail

BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

h()  { echo -e "${BOLD}$*${RESET}"; }
g()  { echo -e "  ${GREEN}$*${RESET}"; }
c()  { echo -e "  ${CYAN}$*${RESET}"; }
ln() { echo -e "  ${YELLOW}──────────────────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           🐝  Hive Drill — command reference        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"

echo ""
h "  ОСНОВНОЙ WORKFLOW"
ln
g "  just new <TASK-ID>              " "Создать задачу (brief в Obsidian)"
g "  just go  <TASK-ID>              " "Полный pipeline: Brief→Plan→Tasks→Code→Tests→Review→PR"
g "  just go-from <ID> <стадия>      " "Продолжить с конкретной стадии (0–6)"
g "  just history <TASK-ID>          " "История чекпоинтов + time travel"

echo ""
h "  ПРОЕКТЫ"
ln
g "  just project add <name> <path>  " "Зарегистрировать проект"
g "  just project switch <name>      " "Переключить активный проект"
g "  just project list               " "Список всех проектов"
g "  just project current            " "Активный проект"
g "  just project info [name]        " "Детали проекта"
g "  just project remove <name>      " "Удалить из реестра"

echo ""
h "  SELF-IMPROVE  (roi работает над собой)"
ln
g "  just self init                  " "Клонировать roi → workspace/roi-dev/"
c "    --repo <git-url>              " "Git remote для клонирования"
c "    --github owner/repo           " "GitHub repo для issues"
g "  just self update                " "git pull workspace"
g "  just self status                " "Статус workspace + активные runs"
g "  just self sync                  " "Commit+push workspace, pull self"

echo ""
h "  ISSUES"
ln
g "  just issues                     " "Полный flow: анализ → fzf выбор → pipeline"
g "  just issues list                " "Показать список с Claude-анализом"
g "  just issues run 42 15 7         " "Запустить pipeline для конкретных issues"

echo ""
h "  ДОКУМЕНТАЦИЯ & CANVAS"
ln
g "  just arch                       " "Схема архитектуры активного проекта"
g "  just arch-of <path>             " "Схема для произвольного проекта"
g "  just docs                       " "Обновить docs в vault (без canvas)"

echo ""
h "  СТАТУС & ПРОВЕРКИ"
ln
g "  just status                     " "Агенты, LLM, MCP, активные runs"
g "  just check [--quick]            " "lint + tests + secrets"
g "  just test [suite...]            " "Тесты (встроенный runner)"

echo ""
h "  WORKTREES"
ln
g "  just wt-create <TASK-ID>        " "Создать git worktree"
g "  just wt-list                    " "Список worktrees"
g "  just wt-clean  <TASK-ID>        " "Удалить worktree"

echo ""
h "  ЛОКАЛЬНЫЙ LLM"
ln
g "  just llm-up                     " "TabbyAPI + кодер 7B"
g "  just llm-writer                 " "TabbyAPI + writer 14B"
g "  just llm-test                   " "Проверить endpoint"
g "  just llm-tunnel                 " "Cloudflare tunnel"

echo ""
h "  ИНИЦИАЛИЗАЦИЯ"
ln
g "  just setup                      " "Полная инициализация"
g "  just setup-mcp                  " "Только MCP серверы"
g "  just setup-gsd                  " "Только GSD хуки"
g "  just completions                " "Установить автодополнения (bash/zsh/fish)"
g "  just man                        " "Man-страница just"

echo ""
c "  Подробнее: just --list  |  just man  |  https://just.systems/man/en/"
echo ""
