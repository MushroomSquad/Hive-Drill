#!/usr/bin/env bash
# tests/test_canvas_arch.sh — Tests for scripts/canvas-arch.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

ARCH_SH="${PROJECT_ROOT}/scripts/canvas-arch.sh"

describe "canvas-arch.sh — --docs mode"

setup_workspace

# canvas-arch.sh uses SCRIPT_DIR/../vault as VAULT root.
# Place script in TEST_REPO/scripts/ so SCRIPT_DIR=TEST_REPO/scripts → PROJECT_ROOT=TEST_REPO
mkdir -p "${TEST_REPO}/scripts" "${TEST_REPO}/vault/canvas" "${TEST_REPO}/vault/docs"
cp "${ARCH_SH}" "${TEST_REPO}/scripts/canvas-arch.sh"

# Create a minimal project with README
cat > "${TEST_REPO}/README.md" <<'EOF'
# My Test Project
A test project for canvas-arch testing.

## Architecture
Describe the architecture here.

## Installation
Install stuff.
EOF

output=$(cd "${TEST_REPO}" && bash scripts/canvas-arch.sh --docs 2>&1)
code=$?

it "exits 0 in --docs mode"
assert_exit_ok $code

it "creates docs/<project-name>.md"
project_name="$(basename "${TEST_REPO}")"
assert_file_exists "${TEST_REPO}/vault/docs/${project_name}.md"

it "docs file contains README content"
project_name="$(basename "${TEST_REPO}")"
assert_file_contains "${TEST_REPO}/vault/docs/${project_name}.md" "My Test Project"

describe "canvas-arch.sh — full mode (generates canvas)"

output=$(cd "${TEST_REPO}" && bash scripts/canvas-arch.sh 2>&1)
code=$?

it "exits 0"
assert_exit_ok $code

it "creates project-arch.canvas"
assert_file_exists "${TEST_REPO}/vault/canvas/project-arch.canvas"

it "canvas is valid JSON"
python3 -c "import json; json.load(open('${TEST_REPO}/vault/canvas/project-arch.canvas'))" 2>/dev/null \
    && pass || fail "Invalid JSON in project-arch.canvas"

it "canvas has nodes array"
nodes=$(python3 -c "import json; d=json.load(open('${TEST_REPO}/vault/canvas/project-arch.canvas')); print(len(d.get('nodes',[])))")
[[ "$nodes" -gt 0 ]] && pass || fail "Canvas has no nodes (got $nodes)"

it "canvas contains project name"
content=$(cat "${TEST_REPO}/vault/canvas/project-arch.canvas")
assert_contains "My Test Project" "$content"

describe "canvas-arch.sh — node project detection"

setup_workspace
mkdir -p "${TEST_REPO}/scripts" "${TEST_REPO}/vault/canvas" "${TEST_REPO}/vault/docs"
cp "${ARCH_SH}" "${TEST_REPO}/scripts/canvas-arch.sh"

cat > "${TEST_REPO}/package.json" <<'EOF'
{
    "name": "my-node-app",
    "description": "A node application",
    "scripts": { "test": "jest", "build": "tsc" },
    "dependencies": { "express": "^4.18.0", "lodash": "^4.17.21" }
}
EOF

output=$(cd "${TEST_REPO}" && bash scripts/canvas-arch.sh 2>&1)

it "detects JavaScript/TypeScript language for node project"
content=$(cat "${TEST_REPO}/vault/canvas/project-arch.canvas")
assert_contains "JavaScript" "$content"

teardown_workspace

describe "canvas-arch.sh — python project detection"

setup_workspace
mkdir -p "${TEST_REPO}/scripts" "${TEST_REPO}/vault/canvas" "${TEST_REPO}/vault/docs"
cp "${ARCH_SH}" "${TEST_REPO}/scripts/canvas-arch.sh"

cat > "${TEST_REPO}/pyproject.toml" <<'EOF'
[project]
name = "my-python-app"
description = "A python application"
dependencies = ["fastapi", "pydantic"]
EOF

output=$(cd "${TEST_REPO}" && bash scripts/canvas-arch.sh 2>&1)

it "detects Python language for pyproject.toml project"
content=$(cat "${TEST_REPO}/vault/canvas/project-arch.canvas")
assert_contains "Python" "$content"

teardown_workspace
print_summary
