# BASE — Project Canon

This file is the single source of truth for project rules.
`AGENTS.md` and `CLAUDE.md` reference it. Do not duplicate rules from BASE.md elsewhere.

---

## Project mission

**Hive Drill** — a self-improving AI development pipeline. A fun side project built entirely
by neural networks: designed, coded, tested, and maintained by AI agents.

Not a toolbox — a **repeatable development factory** with blueprint pipelines, priority-based
task routing, and persistent project memory. The system turns a task idea into a merged PR
through 7 automated stages, using multiple AI agents in isolated git worktrees, with knowledge
managed through an Obsidian vault.

One instance of Hive Drill can work on another instance of itself — picking up GitHub issues,
running the pipeline, and pushing improvements back in a closed loop.

**Target audience**: solo engineers and small teams who want to accelerate AI-assisted
development without losing control. And anyone curious how far a self-directed AI swarm can go.

---


---

## Architecture constraints

**Already decided, not revisited:**

- Architecture: 3-layer (UI → Orchestration → Agents → Tool-bus → Blueprints)
- Pipeline consists of exactly 7 stages (0-6); adding new stages is a P0 decision
- Vault is Obsidian-compatible Markdown, not custom format
- Canvas is Obsidian Canvas JSON format (nodes/edges), not another format
- Agents are isolated via git worktrees (one worktree per agent per task)
- Gate (approval gates) are mandatory at stages 1 and 5; cannot be skipped without explicit flag

**Responsibility zone boundaries:**

| Component | Responsible for |
|-----------|------------|
| `scripts/go.sh` | Pipeline orchestration (7 stages) |
| `scripts/new.sh` | Task creation (brief + kanban) |
| `scripts/project.sh` | Project management (add/switch/list/remove) |
| `scripts/ai-check.sh` | Single done criterion: lint + typecheck + tests + secrets |
| `scripts/gate.sh` | Interactive artifact approval |
| `vault/projects/<name>/` | Isolated Obsidian workspace for project |
| `.ai/runs/<project>/<ID>/` | All artifacts from specific run |
| `.ai/projects/<name>.json` | Project registry (committed) |
| `.ai/state/current` | Active project (local, not committed) |
| `.ai/blueprints/` | Pipeline templates (feature, bugfix, refactor, review, release) |
| `llm/` | Local LLM stack (Harbor + TabbyAPI) |
| `mcp/` | MCP server configuration |

**What must not be touched without explicit decision:**
- Artifact frontmatter format (task_id, status, verdict — required fields)
- Structure of `.ai/runs/<ID>/` (file names are part of contract between agents)
- Git discipline: worktrees, branch naming `agent/<TASK-ID>-<agent>`

---

## Tech stack

| Component | Technology | Version |
|-----------|------------|--------|
| Pipeline runner | Bash | 5.x |
| Task runner | [just](https://just.systems) | 1.x |
| AI agents | Claude Code CLI, Codex CLI | current |
| Local LLM | Harbor + TabbyAPI + llama.cpp | current |
| Kanban / docs | Obsidian (Markdown + Canvas JSON) | current |
| Canvas management | Python 3 (stdlib only) | 3.10+ |
| MCP servers | Node.js / npx | LTS |
| Claude Code hooks | GSD (get-shit-done) v1.30+ | globally |

---

## Build & test commands

```bash
# Run all tests
bash tests/run_tests.sh

# Run specific test
bash tests/run_tests.sh gate canvas

# Project validation (lint + typecheck + tests + secrets)
./scripts/ai-check.sh              # full check
./scripts/ai-check.sh --quick      # lint only
./scripts/ai-check.sh --tests-only # tests only

# Full pipeline for task
just go TASK-ID

# Initialization
./scripts/init.sh --all

# System status
just status
```

---

## Coding standards

- **Language for new code**: Bash (scripts) + Python 3 (stdlib only, canvas only)
- **Naming**: UPPER_CASE for constants, lower_case for local Bash variables
- **All scripts**: `set -euo pipefail` at start
- **Minimum test coverage**: each public script function + happy path + error path
- **Tests**: `tests/run_tests.sh` — built-in test runner without external dependencies
- **Formatter**: none (bash — manually, follow style of existing scripts)
- **Secrets**: never hardcode, only via `.env` (verified in `ai-check.sh`)

---

## Writing standards (humanizer)

**Mandatory** for all text artifacts created by this project:

- All `.md` pipeline documents (`plan.md`, `findings.md`, `pr-body.md`, `brief.md`, `tasks.md`)
- Code comments written by agents
- README and any other documentation

**Rule**: after writing any document or block of comments — pass through `/humanize` (GSD skill `humanizer`).

```bash
# After creating artifact:
/humanize .ai/runs/<TASK-ID>/plan.md
/humanize .ai/runs/<TASK-ID>/findings.md
/humanize .ai/runs/<TASK-ID>/pr-body.md
```

**Why**: AI-generated text contains characteristic patterns (inflated significance, AI vocabulary, em dash overuse, etc.). Humanizer removes them and adds human voice.

**When NOT to apply**: frontmatter fields (task_id, status, verdict) — do not touch them.

---

## GSD (get-shit-done) integration

[GSD](https://github.com/gsd-build/get-shit-done) is installed **globally** (`~/.claude/hooks/`).
Automatically active for all Claude Code sessions in this project.

**What GSD adds to this project:**

| Hook | When | What it does |
|------|-------|------------|
| `gsd-context-monitor.js` | After each tool use | Warns agent when context < 35% / 25% |
| `gsd-prompt-guard.js` | Before Write/Edit in `.planning/` | Scans for prompt injection patterns |
| `gsd-statusline.js` | Always (statusline) | Shows model, context, directory |
| `gsd-check-update.js` | At session start | Checks for GSD updates |

**For this project**: GSD works transparently. No additional configuration needed.
If you want to use GSD workflow (`.planning/` directory), add `.planning/` to `.gitignore`.

---

## What agents may NOT do without explicit approval

- Change artifact frontmatter schema (task_id, status, verdict)
- Change public API of scripts (signatures, exit codes, file names)
- Delete data in production vault
- Change CI/CD pipelines
- Commit secrets, keys, credentials
- Amend published commits
- Change `BASE.md` (requires human review, not agent)

---

## Definition of done

Task is considered complete when:
- [ ] `bash tests/run_tests.sh` passes without errors
- [ ] `./scripts/ai-check.sh` passes without FAIL
- [ ] Unit tests written / updated for changed scripts
- [ ] `verification.md` filled in `.ai/runs/<TASK-ID>/`
- [ ] `pr-body.md` ready
- [ ] No commented-out code
- [ ] No hardcoded secrets

---

## Review rules

1. Every PR must have `pr-body.md` with motivation for changes.
2. Breaking changes require explicit designation in PR.
3. Changes to `.ai/base/BASE.md` require human review, not agent.

---

## Escalation policy

| Situation | Action |
|---------|---------|
| Security issue found | Stop, create findings.md, escalate |
| Unclear bug cause | Stop, write diagnosis, ask human |
| Artifact schema change needed | Stop, write migration plan, ask |
| Diff > 500 lines unexpectedly | Check scope, may need to split |
