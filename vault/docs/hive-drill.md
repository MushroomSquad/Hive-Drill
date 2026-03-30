---
project: roi
extracted: 2026-03-24 20:59
---

# Docs: roi


## README

# AI Dev OS

Production development system with AI: Cursor + Warp + Codex + Claude Code + local LLM stack.

Not a set of tools, but a **factory for repeatable development** with blueprint pipelines, priority-based task routing, and persistent project memory.

---

## System architecture

```
┌─────────────────────────────────────────────────────────────┐
│  UI layer         Cursor (editor, review, manual fixes)      │
├─────────────────────────────────────────────────────────────┤
│  Orchestration    Warp / Oz (terminal, pipeline runner, CI)  │
├─────────────────────────────────────────────────────────────┤
│  Agents           Claude Code (architect) │ Codex (executor)  │
├─────────────────────────────────────────────────────────────┤
│  Tool-bus         MCP (GitHub, Linear, Postgres, Browser...) │
├─────────────────────────────────────────────────────────────┤
│  Blueprints       .ai/ (pipelines, skills, memory, ranks)    │
├─────────────────────────────────────────────────────────────┤
│  Local LLM        llm/ (Harbor + TabbyAPI + llama.cpp)       │
└─────────────────────────────────────────────────────────────┘
```

## Agent roles

| Agent | Role | Priorities |
|-------|------|-----------|
| **Claude Code** | Architect, long-horizon thinker | P0: critical, P1: plan+review |
| **Codex** | Executor, fast engineer | P1: implementation, P2: routine |
| **Cursor** | Cockpit, review, manual fixes | all |
| **Warp/Oz** | Dispatcher, pipeline runner | all automation |
| **Local LLM** | Local backend for P2/P3 tasks | P2: routine, P3: background |

## Task routing

| Priority | Task type | Agent | Model |
|-----------|-----------|-------|--------|
| **P0** critical | security, migration, architecture | Claude Code | opus/opusplan |
| **P1** standard | feature, refactor, integration | Claude Sonnet + Codex cloud | cloud-medium |
| **P2** routine | boilerplate, docs, simple tests | Codex local | local-fast |
| **P3** background | triage, changelogs, search | Codex local | local-cheap |

## Project structure

```
.ai/
  base/          — canon: rules, architecture, done criteria
  blueprints/    — pipeline templates (feature, bugfix, refactor...)
  skills/        — reusable micro-workflows
  pipelines/     — YAML pipelines for Oz/CI
  routing/       — task routing policy
  runs/          — artifacts from each run
  evals/         — golden tests for blueprints
.codex/          — config.toml (cloud + local profiles)
.cursor/rules/   — editor-specific rules
.claude/         — Claude Code settings, skills
mcp/             — MCP server configuration
scripts/         — ai-check, blueprint-run, plan-init, package-pr
llm/             — local LLM stack (Harbor + TabbyAPI + llama.cpp)
```

## Quick start

### 1. Initialize system

```bash
./scripts/init.sh
```

Script: checks dependencies, copies `.env.example` → `.env`, configures MCP, checks local LLM stack.

### 2. Start local LLM

```bash
just llm-up              # TabbyAPI + coder 7B
# or
./llm/setup/install.sh   # first installation
```

### 3. Run blueprint pipeline

```bash
# New feature
just bp feature TASK-123

# Bug fix
just bp bugfix BUG-456

# Code review
just bp review PR-789
```

### 4. Check status

```bash
just status              # all agents and services
./scripts/ai-check.sh    # project validation
```

## Pipeline lifecycle

```
Intake (brief.md)
  → Architectural pass — Claude Code (plan.md)
    → Task slicing — Claude / Cursor (tasks.yaml)
      → Isolated execution — Codex in worktree (code)
        → Verification — scripts/ai-check.sh (verification.md)
          → Narrative review — Claude Code (findings.md)
            → PR packaging — Codex/Cursor (pr-body.md)
              → Retro → update BASE.md / blueprints
```

## Local LLM

More info: [llm/README.md](llm/README.md)

RTX 4070 (12 GB VRAM) — recommended stack: Harbor + TabbyAPI + EXL2.

```bash
cd llm
./setup/install.sh
./models/download-coder.sh
./profiles/tabbyapi-coder.sh
```


## BASE

# BASE — Project Canon

This file is the single source of truth for project rules.
`AGENTS.md` and `CLAUDE.md` reference it. Do not duplicate rules from BASE.md in other files.

---

## Project mission

> Fill in: what this project produces, for whom, and why.

## Architecture constraints

> Fill in: which architectural decisions are already made and are not up for revision.

- [ ] TODO: list of services / modules
- [ ] TODO: boundary of responsibilities
- [ ] TODO: what must not be changed without an explicit team decision

## Tech stack

| Component | Technology | Version |
|-----------|-----------|---------|
| TODO      | TODO      | TODO    |

## Build & test commands

```bash
# Replace with real project commands
# npm run lint
# npm run typecheck
# npm test
# make check
```

## Coding standards

- Language for new code: TODO (choose: Python / TypeScript / Go / etc.)
- Naming: TODO (snake_case / camelCase / etc.)
- Minimum test coverage: TODO %
- Required linter: TODO
- Formatter: TODO

## What agents may NOT do without explicit approval

- Change database schema
- Modify public API (breaking changes)
- Delete production data
- Change CI/CD pipelines
- Commit secrets, keys, credentials
- Amend published commits

## Definition of done

Task is complete when:
- [ ] `scripts/ai-check.sh` passes without errors
- [ ] Unit tests written / updated
- [ ] `verification.md` filled
- [ ] `pr-body.md` ready
- [ ] No commented-out code
- [ ] No hardcoded secrets

## Review rules

1. Every PR must have `pr-body.md` with motivation for changes.
2. Breaking changes require explicit marking in PR.
3. Changes to `.ai/base/BASE.md` require human review, not agent.

## Escalation policy

| Situation | Action |
|---------|--------|
| Security issue found | Stop, create findings.md, escalate |
| Unclear bug cause | Stop, write diagnosis, ask human |
| Need to change DB schema | Stop, write migration plan, ask |
| Diff > 500 lines unexpectedly | Check scope, may need to split |


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

## Memory updates
After every completed pipeline run, check if BASE.md, blueprints, or skills need to be updated based on what was learned. Propose updates explicitly — don't silently modify them.
