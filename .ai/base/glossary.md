# Glossary

Single unified glossary of project terms. Agents must use these terms in code, documentation, and artifacts.

---

## Core domain terms

| Term | Definition |
|--------|------------|
| **Project** | Registered repository with isolated vault and runs. Stored in `.ai/projects/<name>.json` |
| **Active Project** | Currently active project. Set via `just project switch`. Stored in `.ai/state/current` (local, not committed) |
| **Project Registry** | List of all registered projects in `.ai/projects/`. Committed — shared across team |
| **Project Vault** | Isolated Obsidian workspace for project: `vault/projects/<name>/` |

## System terms (AI orchestration)

| Term | Definition |
|--------|------------|
| **Blueprint** | Pipeline template: set of stages, artifacts, handoff rules, and eval criteria |
| **Run** | Specific execution of blueprint for specific task (artifacts in `.ai/runs/<project>/<id>/`) |
| **Brief** | Structured task description: goal, scope, constraints, risks |
| **Plan** | Architectural plan: solution options, chosen path, stages, rollback |
| **Findings** | Post-implementation narrative: what was done, technical debt, follow-ups |
| **Skill** | Reusable micro-workflow for specific recurring operation |
| **P0/P1/P2/P3** | Task priority determining agent and model routing |
| **Cloud lane** | Route via cloud models (Claude Opus/Sonnet, Codex cloud) |
| **Local lane** | Route via local LLM (Codex local profile → localhost:8000) |
| **Worktree** | Isolated repository copy for parallel agent work |
