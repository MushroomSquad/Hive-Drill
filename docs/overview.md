---
project: hive-drill-dev
extracted: 2026-03-30 14:51
---

# Docs: hive-drill-dev


## README

```
                          ╱╲                  ╱╲
                         ╱  ╲                ╱  ╲
                        ╱    ╲              ╱    ╲
           ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
          ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
         ░░░░░░░░░░░░░    ░░░░░░░░░░░░░░░░░    ░░░░░░░░░░░░░
          ░░░░░░░░░░░░░    ░░░░░░░░░░░░░░░    ░░░░░░░░░░░░░
                        ╔═══════════════════╗
                        ║  ◉◉◉         ◉◉◉  ║
                        ║     ╲       ╱     ║
                        ║      ╰─────╯      ║
                        ╠═══════════════════╣
  ◄══◄══◄══◄══◄══◄══◄═══╣ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ╠═══►══►══►══►══►══►══►
  ◄══◄══◄══◄══◄══◄══◄═══╣ ███████████████ ╠═══►══►══►══►══►══►══►
  ◄══◄══◄══◄══◄══◄══◄═══╣ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ╠═══►══►══►══►══►══►══►
                        ║ ███████████████ ║
                        ║ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ║
                        ║ ███████████████ ║
                        ║ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ║
                        ║ ███████████████ ║
                        ╚════════╦══════╝
                                ▓║▓
                               ░─╫─░
                                ▓║▓
                                ─╫─
                               ╱   ╲
```

<h1 align="center">🐝 Hive Drill</h1>
<p align="center"><em>A swarm of AI agents, drilling through your dev backlog.</em></p>

<p align="center">
  <img src="https://img.shields.io/badge/built%20by-AI%20only-yellow?style=flat-square&logo=openai" alt="Built by AI"/>
  <img src="https://img.shields.io/badge/tested%20by-AI%20only-yellow?style=flat-square" alt="Tested by AI"/>
  <img src="https://img.shields.io/badge/maintained%20by-AI%20only-yellow?style=flat-square" alt="Maintained by AI"/>
  <img src="https://img.shields.io/badge/vibe-fun%20experiment-black?style=flat-square" alt="Fun experiment"/>
  <img src="https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash" alt="Bash"/>
</p>

---

> **⚠️ Fair warning:** Hive Drill is a **fun side project** built entirely by neural networks —
> designed, coded, tested, debugged, and documented by AI agents with minimal human
> intervention. It exists because we wanted to see how far a self-directed AI swarm
> could go when given a clear mission and a pile of shell scripts.
> Expect rough edges. That's part of the experiment.

---

## What is Hive Drill?

Hive Drill is a **self-improving AI development pipeline** — a production-grade shell toolkit
that coordinates multiple AI agents (Claude Code, Codex) to take a task from idea to merged PR
through 7 automated stages. One instance of Hive Drill can work on another instance of itself,
pick up GitHub issues, and close the loop autonomously.

Think of it as a **beehive for software development**: each agent has a role, they operate in
isolated git worktrees, share a knowledge vault, and keep improving the hive itself.

```
Idea (brief.md)
  → Stage 1: Architectural plan        [⏸ human gate]
    → Stage 2: Task breakdown
      → Stage 3: Isolated code execution (Codex in git worktree)
        → Stage 4: Automated verification (lint + tests + secrets)
          → Stage 5: Narrative review   [⏸ human gate]
            → Stage 6: PR packaging
```

---

## System architecture

```
┌─────────────────────────────────────────────────────────────┐
│  UI layer        Cursor / editor + Obsidian vault           │
├─────────────────────────────────────────────────────────────┤
│  Orchestration   scripts/go.sh — 7-stage pipeline runner    │
├─────────────────────────────────────────────────────────────┤
│  Agents          Claude Code (architect) │ Codex (executor) │
├─────────────────────────────────────────────────────────────┤
│  Tool-bus        MCP (GitHub, Linear, Postgres, Browser...) │
├─────────────────────────────────────────────────────────────┤
│  Blueprints      .ai/blueprints/ — pipeline templates       │
├─────────────────────────────────────────────────────────────┤
│  Local LLM       llm/ — Harbor + TabbyAPI + llama.cpp       │
└─────────────────────────────────────────────────────────────┘
```

| Agent | Role | Priority |
|-------|------|----------|
| **Claude Code** | Architect, long-horizon thinker | P0: critical, P1: plan + review |
| **Codex** | Executor, fast engineer | P1: implementation, P2: routine |
| **Local LLM** | Background worker | P2: routine, P3: triage |

---

## Quick start

### 1. Bootstrap

```bash
git clone <repo-url> hive-drill
cd hive-drill
./scripts/init.sh --all
```

### 2. Register a project

```bash
# Point Hive Drill at any repo you want to work on
just project add myapp /path/to/myapp "Short description"
just project switch myapp
```

### 3. Create and run a task

```bash
# Create a brief (fills template in Obsidian vault)
just new FEAT-001

# Edit vault/projects/myapp/00-inbox/FEAT-001.md
# Change:  status: draft  →  status: ready

# Fire the full pipeline
just go FEAT-001
```

### 4. Self-improve mode

```bash
# Let Hive Drill work on itself
just self init --repo git@github.com:you/hive-drill.git --github you/hive-drill

# Browse GitHub issues, pick what to work on
just issues

# After the pipeline finishes — commit, push, pull self
just self sync
```

---

## Pipeline stages

| # | Stage | Agent | Artifact | Gate |
|---|-------|-------|----------|------|
| 0 | Brief | Human | `brief.md` | — |
| 1 | Plan | Claude Code | `plan.md` | ⏸ y/n/e |
| 2 | Tasks | Claude Code | `tasks.md` | — |
| 3 | Code | Codex | changes in worktree | — |
| 4 | Tests | scripts | `test-report.md` | — |
| 5 | Review | Claude Code | `findings.md` | ⏸ y/n/e |
| 6 | PR | scripts | `pr-body.md` | — |

---

## Project structure

```
.ai/
  base/          — canonical rules, architecture, done criteria
  blueprints/    — pipeline templates (feature, bugfix, refactor, review, release)
  projects/      — project registry (<name>.json), committed
  runs/          — run artifacts: runs/<project>/<TASK-ID>/
scripts/
  go.sh          — pipeline orchestrator (7 stages)
  new.sh         — task brief creator
  project.sh     — project registry manager
  self.sh        — self-improvement workflow
  issues.sh      — GitHub issues → Claude analysis → fzf picker → pipeline
  canvas-arch.sh — auto-generate architecture canvas + docs
  gate.sh        — interactive human approval gates
  ai-check.sh    — done criterion: lint + tests + secrets
vault/
  projects/      — per-project Obsidian workspace (inbox/active/done/canvas)
  canvas/        — global kanban board
llm/             — local LLM stack (Harbor + TabbyAPI + llama.cpp)
mcp/             — MCP server configuration
tests/           — test suite (zero external dependencies)
```

---

## Commands

```bash
just help               # Full command reference
just --list             # Quick recipe list

just new  <ID>          # Create task brief
just go   <ID>          # Run full pipeline
just go-from <ID> <N>   # Resume from stage N

just project add <name> <path>   # Register project
just project switch <name>       # Switch active project

just self init          # Clone self into workspace/hive-drill-dev/
just self sync          # Commit+push workspace, pull self

just issues             # Browse GitHub issues → pipeline
just issues list        # List + Claude analysis
just issues run 42 7    # Run pipeline for specific issues

just arch               # Generate architecture canvas
just status             # System status (agents, LLM, MCP)
just check              # Full done-check (lint+tests+secrets)

just completions        # Install shell completions (bash/zsh/fish)
just man                # Open just man page
```

---

## Testing

All scripts are covered by a built-in test runner — zero external dependencies.

```bash
bash tests/run_tests.sh          # Run all tests
bash tests/run_tests.sh gate     # Run specific suite
just check                       # Full quality gate
```

---

## Local LLM (optional)

RTX 4070 (12 GB VRAM) recommended stack: Harb

## BASE

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
| 

## AGENTS

# Agent Instructions

Read `.ai/base/BASE.md` first — it is the canonical source of project rules.

## Workflow selection
For any non-trivial task, select the matching blueprint from `.ai/blueprints/`:
- New feature → `.ai/blueprints/feature-v1.md`
- Bug fix → `.ai/blueprints/bugfix-v1.md`
- Refactoring → `.ai/blueprints/refactor-v1.md`
- Code review → `.ai/blueprints/review-v1.md`
- Release → `.ai/blueprints/release-v1.md`

## Execution rules
1. Create a run directory: `.ai/runs/<TASK-ID>/` before starting work.
2. Produce `brief.md` for every task before touching code.
3. Work in a separate git worktree — never directly on the main working tree.
4. Run `scripts/ai-check.sh` after every change set. Do not propose completion before it passes.
5. For repeated operations, prefer existing `scripts/` and `.ai/skills/` instead of improvising.

## Model routing
- You are operating as the **executor** role (Codex / Codex-local).
- For P0 (security, architecture, migration) tasks: stop and escalate to Claude Code.
- For P2/P3 (boilerplate, docs, triage): prefer the local model profile.
- See `.ai/routing/policy.yaml` for the full routing policy.

## Output expectations
- Every completed task must produce: `brief.md`, `tasks.yaml`, relevant output files, `verification.md`.
- All artifacts go into `.ai/runs/<TASK-ID>/`.

## What to avoid
- Do not refactor code that wasn't asked about.
- Do not add error handling, comments, or type annotations not explicitly requested.
- Do not commit secrets. Check `.env.example` for the list of sensitive keys.
- Do not amend existing commits — always create new ones.


## CLAUDE

# Claude Code Instructions

Read `.ai/base/BASE.md` first — it is the single source of project truth.

## My role in this system
I am the **architect and long-horizon thinker**. My primary responsibilities:
- Decompose complex tasks into actionable plans
- Write `plan.md` and `tasks.yaml` for Codex execution
- Do architectural risk analysis and narrative review
- Handle P0 (critical) tasks end-to-end
- Write `findings.md` after implementation is done

## Default operating mode
**Plan first, implement in small verified steps.**

Before writing any code on a non-trivial task:
1. Read the relevant files (don't assume structure)
2. Write a plan — options, chosen approach, risks, rollback
3. Get implicit or explicit confirmation before executing
4. Produce run artifacts in `.ai/runs/<TASK-ID>/`

## Workflow templates
Use blueprints from `.ai/blueprints/` as the template for every pipeline run.
Store all artifacts in `.ai/runs/<TASK-ID>/`.

## Git discipline
- Work in git worktrees for parallel/isolated tasks
- Branch naming: `<agent>/<task-id>-<short-description>`
- Never force push. Never amend published commits.
- Run `scripts/ai-check.sh` before marking any task done.

## Model routing (opusplan)
- For planning and architecture: use Opus / opusplan
- For implementation execution: Sonnet is appropriate
- Subagent tasks: use `CLAUDE_CODE_SUBAGENT_MODEL` if set

## Escalation
If I discover a P0 issue (security flaw, data migration risk, unclear architectural impact) while executing a P1/P2 task:
1. Stop current work
2. Write a findings note in `.ai/runs/<TASK-ID>/findings.md`
3. Ask the human for direction before proceeding

## Writing standards
After writing any `.md` artifact (`plan.md`, `findings.md`, `pr-body.md`) or code comments — run `/humanize` on the text before finalizing. See BASE.md § Writing standards for details.

## Memory updates
After every completed pipeline run, check if BASE.md, blueprints, or skills need to be updated based on what was learned. Propose updates explicitly — don't silently modify them.
