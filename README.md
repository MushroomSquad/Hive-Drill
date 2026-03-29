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

just self init          # Clone self into workspace/roi-dev/
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

RTX 4070 (12 GB VRAM) recommended stack: Harbor + TabbyAPI + EXL2.

```bash
just llm-up       # TabbyAPI + Qwen2.5-Coder 7B (daily coding)
just llm-writer   # TabbyAPI + Qwen2.5 14B (docs, planning)
just llm-test     # Verify endpoint
just llm-tunnel   # Cloudflare tunnel for remote access
```

---

## Dependencies

| Tool | Required | Purpose |
|------|----------|---------|
| `bash` 5.x | ✅ | Everything |
| `just` | ✅ | Task runner |
| `claude` CLI | ✅ | Architect agent |
| `codex` CLI | ✅ | Executor agent |
| `python3` | ✅ | Canvas generation (stdlib only) |
| `gh` CLI | ✅ for issues | GitHub issues workflow |
| `fzf` | ✅ for issues | Interactive picker |
| `git` | ✅ | Worktrees, self-update |
| Harbor + TabbyAPI | optional | Local LLM |
| Obsidian | optional | Vault visualization |

Install everything:
```bash
just setup
just completions   # → shell tab completion for all just commands
```

---

## The experiment

This project answers one question: **can a swarm of AI agents build and maintain
a non-trivial software tool with minimal human direction?**

Rules of the experiment:
- No human writes code directly
- All changes go through the pipeline
- AI agents write the tests and run them
- Self-improvement is the end goal: `just issues` → `just self sync` → repeat

Current status: **ongoing**. The hive is active.

---

## License

MIT — do whatever you want with it. It was made by robots anyway.

---

<p align="center">
  <sub>🐝 Hive Drill — because why debug manually when you have a swarm?</sub><br>
  <sub>Made with 🍄 by MushroomSquad</sub>
</p>
