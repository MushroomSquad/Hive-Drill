#!/usr/bin/env bash
# Запускает blueprint-пайплайн для задачи
# Использование: ./scripts/blueprint-run.sh <blueprint> <TASK-ID> [stage]
#
# Примеры:
#   ./scripts/blueprint-run.sh feature TASK-123
#   ./scripts/blueprint-run.sh bugfix BUG-456
#   ./scripts/blueprint-run.sh review PR-789
#   ./scripts/blueprint-run.sh feature TASK-123 arch   # только stage 1
set -euo pipefail

BLUEPRINT="${1:?Usage: $0 <blueprint> <TASK-ID> [stage]}"
TASK_ID="${2:?Usage: $0 <blueprint> <TASK-ID> [stage]}"
STAGE="${3:-all}"

RUN_DIR=".ai/runs/$TASK_ID"
PIPELINE_FILE=".ai/pipelines/${BLUEPRINT}.yaml"
BLUEPRINT_FILE=".ai/blueprints/${BLUEPRINT}-v1.md"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[DONE]${NC} $*"; }
info() { echo -e "${CYAN}[RUN]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

# Проверки
[ -f "$PIPELINE_FILE" ] || die "Pipeline не найден: $PIPELINE_FILE"
[ -f "$BLUEPRINT_FILE" ] || die "Blueprint не найден: $BLUEPRINT_FILE"

# Инициализировать run если не существует
if [ ! -d "$RUN_DIR" ]; then
  info "Инициализирую run: $TASK_ID"
  ./scripts/plan-init.sh "$TASK_ID" "$BLUEPRINT"
  echo ""
  echo "Заполни $RUN_DIR/brief.md и перезапусти команду."
  exit 0
fi

# Проверить что brief.md заполнен
if grep -q "^## Goal" "$RUN_DIR/brief.md" && \
   ! grep -A1 "^## Goal" "$RUN_DIR/brief.md" | grep -q "^<!-- "; then
  : # OK
else
  die "brief.md не заполнен. Отредактируй: $RUN_DIR/brief.md"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Blueprint: $BLUEPRINT | Task: $TASK_ID"
printf "║  Stage: %-42s║\n" "$STAGE"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Запуск по стадиям ─────────────────────────────────────────────────

run_stage() {
  local stage_id="$1"
  local stage_name="$2"
  local stage_owner="$3"
  local stage_cmd="$4"

  info "Stage: $stage_name (owner: $stage_owner)"

  case "$stage_owner" in
    scripts)
      eval "$stage_cmd"
      ;;
    claude)
      if command -v claude &>/dev/null; then
        eval "$stage_cmd"
      else
        warn "claude CLI не найден — выполни вручную:"
        echo "  $stage_cmd"
      fi
      ;;
    codex)
      if command -v codex &>/dev/null; then
        eval "$stage_cmd"
      else
        warn "codex CLI не найден — выполни вручную:"
        echo "  $stage_cmd"
      fi
      ;;
    human)
      warn "Требуется ручное действие:"
      echo "  $stage_cmd"
      ;;
  esac
}

# Маппинг blueprint → команды по стадиям
case "$BLUEPRINT" in
  feature)
    if [[ "$STAGE" == "all" || "$STAGE" == "arch" ]]; then
      run_stage "arch" "Architectural pass" "claude" \
        "claude --model opus 'Read .ai/blueprints/feature-v1.md Stage 1 and .ai/runs/$TASK_ID/brief.md. Produce .ai/runs/$TASK_ID/plan.md.'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "slice" ]]; then
      [ -f "$RUN_DIR/plan.md" ] || die "Нет plan.md — сначала запусти stage arch"
      run_stage "slice" "Task slicing" "claude" \
        "claude 'Read .ai/blueprints/feature-v1.md Stage 2. Read .ai/runs/$TASK_ID/plan.md. Produce .ai/runs/$TASK_ID/tasks.yaml.'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "exec" ]]; then
      [ -f "$RUN_DIR/tasks.yaml" ] || die "Нет tasks.yaml — сначала запусти stage slice"
      ./scripts/worktree.sh create "$TASK_ID" || true
      info "Worktree готов. Запусти Codex вручную в wt/$TASK_ID-codex:"
      echo "  cd wt/$TASK_ID-codex"
      echo "  codex --profile cloud-medium 'Execute tasks from ../.ai/runs/$TASK_ID/tasks.yaml'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "verify" ]]; then
      run_stage "verify" "Verification" "scripts" \
        "AI_CHECK_LOG='.ai/runs/$TASK_ID/verification.md' ./scripts/ai-check.sh"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "review" ]]; then
      [ -f "$RUN_DIR/verification.md" ] || die "Нет verification.md — сначала запусти verify"
      run_stage "review" "Narrative review" "claude" \
        "claude 'Read .ai/blueprints/feature-v1.md Stage 5. Read .ai/runs/$TASK_ID/verification.md and plan.md. Produce .ai/runs/$TASK_ID/findings.md.'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "package" ]]; then
      [ -f "$RUN_DIR/findings.md" ] || die "Нет findings.md — сначала запусти review"
      run_stage "package" "PR packaging" "codex" \
        "codex 'Read .ai/blueprints/feature-v1.md Stage 6. Read .ai/runs/$TASK_ID/brief.md and findings.md. Produce .ai/runs/$TASK_ID/pr-body.md.'"
    fi
    ;;

  bugfix)
    if [[ "$STAGE" == "all" || "$STAGE" == "diagnose" ]]; then
      run_stage "diagnose" "Diagnosis" "claude" \
        "claude --model opus 'Read .ai/blueprints/bugfix-v1.md Stage 1. Read .ai/runs/$TASK_ID/brief.md. Produce .ai/runs/$TASK_ID/plan.md.'"
    fi
    ;;

  review)
    run_stage "review" "Code review" "claude" \
      "claude --model sonnet 'Read .ai/blueprints/review-v1.md. Review the current diff. Produce .ai/runs/$TASK_ID/findings.md.'"
    ;;
esac

echo ""
ok "Pipeline '$BLUEPRINT' для $TASK_ID — текущий stage завершён"
echo ""
echo "Артефакты: $RUN_DIR/"
ls -la "$RUN_DIR/" 2>/dev/null | awk 'NR>1{print "  " $NF}'
