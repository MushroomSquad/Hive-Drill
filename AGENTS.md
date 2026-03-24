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
