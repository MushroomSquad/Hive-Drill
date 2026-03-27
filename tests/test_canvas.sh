#!/usr/bin/env bash
# tests/test_canvas.sh — Tests for canvas-add.sh and canvas-move.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

CANVAS_ADD="${PROJECT_ROOT}/scripts/canvas-add.sh"
CANVAS_MOVE="${PROJECT_ROOT}/scripts/canvas-move.sh"

# ─── Helper: create a minimal canvas file ─────────────────────────────────────
make_canvas() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    echo '{"nodes":[],"edges":[]}' > "$path"
}

describe "canvas-add.sh — argument validation"

it "exits 1 with no arguments"
output=$("${CANVAS_ADD}" 2>&1); code=$?
assert_exit_fail $code

describe "canvas-add.sh — adding a card"

setup_workspace

# canvas-add.sh resolves canvas path as SCRIPT_DIR/../vault/canvas/project-board.canvas
# So we copy the script into scripts/ and create vault/ next to it
mkdir -p "${TEST_TMPDIR}/scripts" "${TEST_TMPDIR}/vault/canvas"
cp "${CANVAS_ADD}" "${TEST_TMPDIR}/scripts/canvas-add.sh"
CANVAS="${TEST_TMPDIR}/vault/canvas/project-board.canvas"
make_canvas "$CANVAS"

output=$(cd "${TEST_TMPDIR}" && bash scripts/canvas-add.sh FEAT-001 feature p1 "Test title" backlog 2>&1)

it "exits 0 when canvas exists"
[[ "$output" != *"not found"* ]] && { code=0; } || { code=1; }
assert_exit_ok $code

it "adds a node to the canvas JSON"
node_count=$(python3 -c "import json; d=json.load(open('${CANVAS}')); print(len(d['nodes']))")
assert_equals "1" "$node_count"

it "node text contains task id"
node_text=$(python3 -c "import json; d=json.load(open('${CANVAS}')); print(d['nodes'][0]['text'])")
assert_contains "FEAT-001" "$node_text"

it "node is placed in backlog column (x=20)"
node_x=$(python3 -c "import json; d=json.load(open('${CANVAS}')); print(d['nodes'][0]['x'])")
assert_equals "20" "$node_x"

describe "canvas-add.sh — duplicate guard"

it "does not duplicate an existing card"
output2=$(cd "${TEST_TMPDIR}" && bash scripts/canvas-add.sh FEAT-001 feature p1 "" backlog 2>&1)
node_count2=$(python3 -c "import json; d=json.load(open('${CANVAS}')); print(len(d['nodes']))")
assert_equals "1" "$node_count2"

it "prints 'уже существует' on duplicate"
assert_contains "уже существует" "$output2"

describe "canvas-add.sh — priority colors"

make_canvas "$CANVAS"

cd "${TEST_TMPDIR}" && bash scripts/canvas-add.sh P0-001 bugfix p0 "" backlog 2>/dev/null || true
cd "${SCRIPT_DIR}"
it "p0 card gets color '1' (red)"
color=$(python3 -c "import json; d=json.load(open('${CANVAS}')); [print(n['color']) for n in d['nodes'] if 'P0-001' in n.get('text','')]")
assert_equals "1" "$color"

teardown_workspace

describe "canvas-move.sh — argument validation"

it "exits 1 with no arguments"
output=$("${CANVAS_MOVE}" 2>&1); code=$?
assert_exit_fail $code

it "exits 1 with only one argument"
output=$("${CANVAS_MOVE}" FEAT-001 2>&1); code=$?
assert_exit_fail $code

describe "canvas-move.sh — moving a card"

setup_workspace

# canvas-move.sh resolves canvas as SCRIPT_DIR/../vault/canvas/project-board.canvas
mkdir -p "${TEST_TMPDIR}/scripts" "${TEST_TMPDIR}/vault/canvas"
cp "${CANVAS_MOVE}" "${TEST_TMPDIR}/scripts/canvas-move.sh"
CANVAS="${TEST_TMPDIR}/vault/canvas/project-board.canvas"

# Canvas with one card in backlog
python3 -c "
import json
data = {
    'nodes': [{'id': 'card-1', 'type': 'text', 'text': '**FEAT-001**\np1 · feature', 'x': 20, 'y': 440, 'width': 200, 'height': 80}],
    'edges': []
}
with open('${CANVAS}', 'w') as f:
    json.dump(data, f)
"

output=$(cd "${TEST_TMPDIR}" && bash scripts/canvas-move.sh FEAT-001 inprogress 2>&1)

it "exits 0 (prints info, not error)"
[[ "$output" != *"Canvas не найден"* ]] && { code=0; } || { code=1; }
assert_exit_ok $code

it "moves card to inprogress column (x=580)"
new_x=$(python3 -c "import json; d=json.load(open('${CANVAS}')); print(d['nodes'][0]['x'])")
assert_equals "580" "$new_x"

it "handles unknown lane gracefully (exit 0)"
output2=$(cd "${TEST_TMPDIR}" && bash scripts/canvas-move.sh FEAT-001 INVALID_LANE 2>&1)
code2=$?
# Script calls sys.exit(0) for unknown lane, so bash exits 0
assert_exit_ok $code2

it "prints warning for unknown lane"
assert_contains "Неизвестная lane" "$output2"

it "does not crash when card not found in canvas"
output3=$(cd "${TEST_TMPDIR}" && bash scripts/canvas-move.sh NONEXISTENT-999 done 2>&1); code3=$?
assert_exit_ok $code3

teardown_workspace
print_summary
