#!/usr/bin/env bash
# canvas-arch.sh — generates canvas diagram of project architecture
# Reads: README, pyproject.toml/package.json, directory structure
# Writes: vault/canvas/project-arch.canvas
#
# Usage:
#   ./scripts/canvas-arch.sh                    — diagram of current project
#   ./scripts/canvas-arch.sh /path/to/project   — diagram of external project
#   ./scripts/canvas-arch.sh --docs             — update docs/ in vault only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VAULT="${PROJECT_ROOT}/vault"
CANVAS_DIR="${VAULT}/canvas"
DOCS_DIR="${VAULT}/docs"

DOCS_ONLY=false
[[ "${1:-}" == "--docs" ]] && DOCS_ONLY=true

# Resolve target project: explicit arg → active project → roi root
if [[ "${1:-}" == "--docs" || -z "${1:-}" ]]; then
    TARGET_PROJECT=""
    ACTIVE_PROJECT_NAME=""
    CURRENT_FILE="${PROJECT_ROOT}/.ai/state/current"
    if [[ -f "${CURRENT_FILE}" ]]; then
        _current="$(cat "${CURRENT_FILE}" | tr -d '[:space:]')"
        if [[ -n "${_current}" ]]; then
            _cfg="${PROJECT_ROOT}/.ai/projects/${_current}.json"
            if [[ -f "${_cfg}" ]]; then
                _path="$(python3 -c "import json; print(json.load(open('${_cfg}')).get('path',''))" 2>/dev/null || echo "")"
                if [[ -n "${_path}" ]]; then
                    TARGET_PROJECT="${_path}"
                    ACTIVE_PROJECT_NAME="${_current}"
                fi
            fi
        fi
    fi
    [[ -z "${TARGET_PROJECT}" ]] && TARGET_PROJECT="${PROJECT_ROOT}"
else
    TARGET_PROJECT="${1}"
    ACTIVE_PROJECT_NAME=""
fi

# Route canvas/docs to project-isolated vault when active project is set
if [[ -n "${ACTIVE_PROJECT_NAME}" ]]; then
    CANVAS_DIR="${VAULT}/projects/${ACTIVE_PROJECT_NAME}/canvas"
    DOCS_DIR="${VAULT}/projects/${ACTIVE_PROJECT_NAME}"
fi

mkdir -p "${CANVAS_DIR}" "${DOCS_DIR}"

info() { echo "  [arch] $*"; }
ok()   { echo "  [OK]   $*"; }
warn() { echo "  [WARN] $*"; }

# ─── Collect project metadata ───────────────────────────────────────────────
collect_metadata() {
    python3 - "${TARGET_PROJECT}" <<'PYEOF'
import json, os, sys, re
from pathlib import Path

root = Path(sys.argv[1])

meta = {
    "name": root.name,
    "description": "",
    "language": "unknown",
    "deps": [],
    "dirs": [],
    "readme_sections": [],
    "scripts": [],
    "entry_points": [],
}

# pyproject.toml
pyproject = root / "pyproject.toml"
if pyproject.exists():
    text = pyproject.read_text(encoding="utf-8")
    meta["language"] = "Python"
    m = re.search(r'^name\s*=\s*"([^"]+)"', text, re.M)
    if m: meta["name"] = m.group(1)
    m = re.search(r'^description\s*=\s*"([^"]+)"', text, re.M)
    if m: meta["description"] = m.group(1)
    deps = re.findall(r'^\s+"([a-zA-Z0-9_-]+)[>=<!\[]?', text, re.M)
    meta["deps"] = list(dict.fromkeys(d for d in deps if d not in ("python","setuptools","wheel")))[:12]
    scripts = re.findall(r'^(\w[\w-]*)\s*=\s*"[^"]+"', text, re.M)
    meta["scripts"] = scripts[:6]

# package.json
pkg = root / "package.json"
if pkg.exists() and not pyproject.exists():
    try:
        data = json.loads(pkg.read_text(encoding="utf-8"))
        meta["language"] = "JavaScript/TypeScript"
        meta["name"] = data.get("name", meta["name"])
        meta["description"] = data.get("description", "")
        deps = list(data.get("dependencies", {}).keys())[:8]
        dev_deps = list(data.get("devDependencies", {}).keys())[:4]
        meta["deps"] = deps + dev_deps
        meta["scripts"] = list(data.get("scripts", {}).keys())[:6]
    except Exception:
        pass

# go.mod
gomod = root / "go.mod"
if gomod.exists():
    meta["language"] = "Go"
    m = re.search(r'^module\s+(\S+)', gomod.read_text(), re.M)
    if m: meta["name"] = m.group(1).split("/")[-1]

# Cargo.toml
cargo = root / "Cargo.toml"
if cargo.exists():
    meta["language"] = "Rust"
    text = cargo.read_text(encoding="utf-8")
    m = re.search(r'^name\s*=\s*"([^"]+)"', text, re.M)
    if m: meta["name"] = m.group(1)

# README
for readme in ("README.md", "README.rst", "readme.md"):
    readme_path = root / readme
    if readme_path.exists():
        text = readme_path.read_text(encoding="utf-8", errors="ignore")
        # Top-level headers as sections
        sections = re.findall(r'^#{1,2}\s+(.+)', text, re.M)
        meta["readme_sections"] = sections[:10]
        if not meta["description"]:
            # First paragraph as description
            lines = text.split("\n")
            for i, line in enumerate(lines):
                if line.startswith("#"): continue
                if line.strip():
                    meta["description"] = line.strip()[:120]
                    break
        break

# Directory structure (top level, excluding utilities)
skip = {".git", ".venv", "venv", "__pycache__", "node_modules", ".DS_Store",
        ".mypy_cache", ".ruff_cache", "dist", "build", ".pytest_cache"}
dirs = []
for item in sorted(root.iterdir()):
    if item.name in skip or item.name.startswith("."): continue
    if item.is_dir():
        # Count nested files
        n = sum(1 for _ in item.rglob("*") if _.is_file() and _.suffix in
                (".py",".ts",".js",".go",".rs",".java",".sh",".md"))
        dirs.append({"name": item.name, "files": n})
dirs = sorted(dirs, key=lambda d: -d["files"])[:10]
meta["dirs"] = dirs

# Entry points
for ep in ("__main__.py", "main.py", "src/main.py", "cmd/main.go", "src/index.ts",
           "app.py", "server.py", "src/lib.rs", "main.go"):
    if (root / ep).exists():
        meta["entry_points"].append(ep)

print(json.dumps(meta, ensure_ascii=False))
PYEOF
}

# ─── Generate canvas ──────────────────────────────────────────────────────
generate_canvas() {
    local meta_json="$1"
    local out_canvas="${CANVAS_DIR}/project-arch.canvas"

    python3 - "${meta_json}" "${out_canvas}" <<'PYEOF'
import json, sys, random, string

meta = json.loads(sys.argv[1])
out_path = sys.argv[2]

def uid():
    return "n-" + "".join(random.choices(string.ascii_lowercase + string.digits, k=8))

nodes = []
edges = []

def node(id_, text, x, y, w, h, color="6"):
    nodes.append({"id": id_, "type": "text", "text": text,
                  "x": x, "y": y, "width": w, "height": h, "color": color})

def edge(src, dst, label=""):
    e = {"id": uid(), "fromNode": src, "fromSide": "right",
         "toNode": dst, "toSide": "left"}
    if label: e["label"] = label
    edges.append(e)

# Title
node("title",
     f"# {meta['name']}\n{meta['description'][:80] if meta['description'] else ''}",
     300, -80, 400, 60, "6")

# Language / stack
lang_text = f"## 🔧 Tech Stack\n\n**Language:** {meta['language']}\n\n"
if meta['deps']:
    lang_text += "**Dependencies:**\n" + "\n".join(f"- `{d}`" for d in meta['deps'][:8])
node("stack", lang_text, 0, 20, 240, max(160, 60 + len(meta['deps'][:8]) * 22), "3")

# Entry points
if meta["entry_points"]:
    ep_text = "## 🚀 Entry Points\n\n" + "\n".join(f"- `{e}`" for e in meta["entry_points"])
    node("entry", ep_text, 0, 250, 240, max(100, 40 + len(meta["entry_points"]) * 28), "1")
    edge("entry", "dirs-group")

# Directory structure
if meta["dirs"]:
    dirs_text = "## 📁 Structure\n\n"
    for d in meta["dirs"]:
        n = d["files"]
        bar = "█" * min(n // 5 + 1, 8)
        dirs_text += f"`{d['name']}/` {bar} {n} files\n"
    node("dirs-group", dirs_text, 300, 60, 260, max(140, 40 + len(meta["dirs"]) * 26), "5")
    edge("stack", "dirs-group", "depends")

# README sections as cards
if meta["readme_sections"]:
    sec_text = "## 📖 README\n\n" + "\n".join(f"- {s}" for s in meta["readme_sections"][:8])
    node("readme", sec_text, 620, 60, 220, max(120, 40 + len(meta["readme_sections"][:8]) * 24), "4")
    edge("dirs-group", "readme", "docs")

# Scripts / commands
if meta["scripts"]:
    sc_text = "## ⚡ Scripts\n\n" + "\n".join(f"`{s}`" for s in meta["scripts"][:6])
    node("scripts", sc_text, 300, 320, 200, max(120, 40 + len(meta["scripts"][:6]) * 26), "6")
    edge("stack", "scripts")

# Tests
test_dirs = [d for d in meta["dirs"] if "test" in d["name"].lower()]
if test_dirs:
    t_text = "## 🧪 Tests\n\n" + "\n".join(f"`{d['name']}/` — {d['files']} files" for d in test_dirs)
    node("tests", t_text, 620, 320, 220, max(100, 40 + len(test_dirs) * 28), "1")
    edge("dirs-group", "tests", "coverage")

data = {"nodes": nodes, "edges": edges}
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f"[arch] Canvas written: {out_path}")
PYEOF

    # Duplicate canvas to project itself
    local project_docs="${TARGET_PROJECT}/docs"
    mkdir -p "${project_docs}"
    cp "${out_canvas}" "${project_docs}/architecture.canvas"
    info "Canvas duplicated to project: ${project_docs}/architecture.canvas"
}

# ─── Save docs from README and BASE ─────────────────────────────────────────
extract_docs() {
    local project="$1"
    local project_name
    project_name="$(basename "${project}")"
    local doc_file="${DOCS_DIR}/${project_name}.md"

    info "Extracting documentation from ${project}…"

    python3 - "${project}" "${doc_file}" "${project_name}" <<'PYEOF'
import sys, re, os
from pathlib import Path
from datetime import datetime

project = Path(sys.argv[1])
out_path = sys.argv[2]
name = sys.argv[3]

sections = []
sections.append(f"---\nproject: {name}\nextracted: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n---\n")
sections.append(f"# Docs: {name}\n")

# README
for readme in ("README.md", "docs/README.md", "readme.md"):
    p = project / readme
    if p.exists():
        text = p.read_text(encoding="utf-8", errors="ignore")[:8000]
        sections.append(f"\n## README\n\n{text}")
        break

# BASE.md / AGENTS.md / CLAUDE.md
for spec in (".ai/base/BASE.md", "AGENTS.md", "CLAUDE.md", "docs/architecture.md"):
    p = project / spec
    if p.exists():
        text = p.read_text(encoding="utf-8", errors="ignore")[:3000]
        label = spec.split("/")[-1].replace(".md", "")
        sections.append(f"\n## {label}\n\n{text}")

# pyproject.toml / package.json — dependencies
for dep_file in ("pyproject.toml", "package.json", "Cargo.toml", "go.mod"):
    p = project / dep_file
    if p.exists():
        text = p.read_text(encoding="utf-8", errors="ignore")[:2000]
        sections.append(f"\n## {dep_file}\n\n```\n{text}\n```")
        break

content = "\n".join(sections)
with open(out_path, "w", encoding="utf-8") as f:
    f.write(content)
print(f"[arch] Docs written: {out_path}")

# Full overview document to project itself
import os
docs_dir = project / "docs"
docs_dir.mkdir(exist_ok=True)
overview_path = docs_dir / "overview.md"
with open(overview_path, "w", encoding="utf-8") as f:
    f.write(content)
print(f"[arch] Documentation written to project: {overview_path}")
PYEOF
}

# ─── Main ─────────────────────────────────────────────────────────────────────
if $DOCS_ONLY; then
    extract_docs "${TARGET_PROJECT}"
    ok "Docs updated in ${DOCS_DIR}/"
    exit 0
fi

if [[ -n "${ACTIVE_PROJECT_NAME}" ]]; then
    info "Active project: ${ACTIVE_PROJECT_NAME} (${TARGET_PROJECT})"
else
    info "Analyzing project: ${TARGET_PROJECT}"
fi

META_JSON="$(collect_metadata)"
generate_canvas "${META_JSON}"
extract_docs "${TARGET_PROJECT}"

ok "Done."
echo ""
echo "  Canvas:  ${CANVAS_DIR}/project-arch.canvas"
echo "  Docs:    ${DOCS_DIR}/$(basename "${TARGET_PROJECT}").md"
if [[ -n "${ACTIVE_PROJECT_NAME}" ]]; then
    echo ""
    echo "  Open in Obsidian: vault/projects/${ACTIVE_PROJECT_NAME}/canvas/project-arch.canvas"
else
    echo ""
    echo "  Open in Obsidian: vault/canvas/project-arch.canvas"
fi
