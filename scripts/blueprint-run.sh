#!/usr/bin/env bash
# Runs blueprint pipeline for task
# Usage: ./scripts/blueprint-run.sh <blueprint> <TASK-ID> [stage]
#
# Examples:
#   ./scripts/blueprint-run.sh feature TASK-123
#   ./scripts/blueprint-run.sh bugfix BUG-456
#   ./scripts/blueprint-run.sh review PR-789
#   ./scripts/blueprint-run.sh feature TASK-123 arch   # only stage 1
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

# Checks
[ -f "$PIPELINE_FILE" ] || die "Pipeline not found: $PIPELINE_FILE"
[ -f "$BLUEPRINT_FILE" ] || die "Blueprint not found: $BLUEPRINT_FILE"

# Initialize run if doesn't exist
if [ ! -d "$RUN_DIR" ]; then
  info "Initializing run: $TASK_ID"
  ./scripts/plan-init.sh "$TASK_ID" "$BLUEPRINT"
  echo ""
  echo "Fill $RUN_DIR/brief.md and re-run command."
  exit 0
fi

# Check that brief.md is filled
if grep -q "^## Goal" "$RUN_DIR/brief.md" && \
   ! grep -A1 "^## Goal" "$RUN_DIR/brief.md" | grep -q "^<!-- "; then
  : # OK
else
  die "brief.md not filled. Edit: $RUN_DIR/brief.md"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Blueprint: $BLUEPRINT | Task: $TASK_ID"
printf "║  Stage: %-42s║\n" "$STAGE"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Run by stages ─────────────────────────────────────────────────

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
        warn "claude CLI not found — run manually:"
        echo "  $stage_cmd"
      fi
      ;;
    codex)
      if command -v codex &>/dev/null; then
        eval "$stage_cmd"
      else
        warn "codex CLI not found — run manually:"
        echo "  $stage_cmd"
      fi
      ;;
    human)
      warn "Manual action required:"
      echo "  $stage_cmd"
      ;;
  esac
}

# Map blueprint → stage commands
case "$BLUEPRINT" in
  feature)
    if [[ "$STAGE" == "all" || "$STAGE" == "arch" ]]; then
      run_stage "arch" "Architectural pass" "claude" \
        "claude --model opus 'Read .ai/blueprints/feature-v1.md Stage 1 and .ai/runs/$TASK_ID/brief.md. Produce .ai/runs/$TASK_ID/plan.md.'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "slice" ]]; then
      [ -f "$RUN_DIR/plan.md" ] || die "No plan.md — run stage arch first"
      run_stage "slice" "Task slicing" "claude" \
        "claude 'Read .ai/blueprints/feature-v1.md Stage 2. Read .ai/runs/$TASK_ID/plan.md. Produce .ai/runs/$TASK_ID/tasks.yaml.'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "exec" ]]; then
      [ -f "$RUN_DIR/tasks.yaml" ] || die "No tasks.yaml — run stage slice first"
      ./scripts/worktree.sh create "$TASK_ID" || true
      info "Worktree ready. Run Codex manually in wt/$TASK_ID-codex:"
      echo "  cd wt/$TASK_ID-codex"
      echo "  codex --profile cloud-medium 'Execute tasks from ../.ai/runs/$TASK_ID/tasks.yaml'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "verify" ]]; then
      run_stage "verify" "Verification" "scripts" \
        "AI_CHECK_LOG='.ai/runs/$TASK_ID/verification.md' ./scripts/ai-check.sh"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "review" ]]; then
      [ -f "$RUN_DIR/verification.md" ] || die "No verification.md — run verify first"
      run_stage "review" "Narrative review" "claude" \
        "claude 'Read .ai/blueprints/feature-v1.md Stage 5. Read .ai/runs/$TASK_ID/verification.md and plan.md. Produce .ai/runs/$TASK_ID/findings.md.'"
    fi
    if [[ "$STAGE" == "all" || "$STAGE" == "package" ]]; then
      [ -f "$RUN_DIR/findings.md" ] || die "No findings.md — run review first"
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
ok "Pipeline '$BLUEPRINT' for $TASK_ID — current stage complete"
echo ""
echo "Artifacts: $RUN_DIR/"
ls -la "$RUN_DIR/" 2>/dev/null | awk 'NR>1{print "  " $NF}'
