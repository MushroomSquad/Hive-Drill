# 🐝 Hive Drill — Home

## Boards

- [[canvas/project-board|Project Board — Task Kanban]]
- [[canvas/pipeline-flow|Pipeline Flow — 7 stages]]
- [[canvas/architecture|Architecture — System diagram]]
- [[canvas/project-arch|Project Arch — Current project diagram]] *(generated: `just arch`)*

---

## Active tasks

```dataview
TABLE task_id, status, priority, owner
FROM "01-active"
WHERE file.name != "README"
SORT priority ASC
```

---

## Commands

**Projects**

| Command | What it does |
|---|---|
| `just project add <name> <path>` | Register project |
| `just project switch <name>` | Switch to project |
| `just project list` | List all projects |
| `just project current` | Active project |
| `just project info` | Active project details |

**Pipeline**

| Command | What it does |
|---|---|
| `just new TASK-ID` | Create new task (brief in active project inbox) |
| `just go TASK-ID` | Run full pipeline |
| `just go-from TASK-ID STAGE` | Continue from a stage |
| `just status` | Show system and project status |
| `just wt-list` | List git worktrees |
| `just arch` | Generate canvas diagram of current project |
| `just arch-of /path` | Generate diagram of external project |
| `just docs` | Update documentation in vault/docs/ |

---

## How to work

1. **Create a task** — `just new FEAT-001` — opens template file in `00-inbox/`
2. **Fill in brief** — describe goal, scope, acceptance criteria
3. **Change status** — `status: draft` → `status: ready` in frontmatter
4. **Run pipeline** — `just go FEAT-001` — system goes through all stages automatically
5. **Approve gates** — on Plan and Review stages system will stop and show artifact: `y` to continue, `e` to edit, `n` to stop

---

## Pipeline stages

| # | Stage | Agent | Gate |
|---|---|---|---|
| 0 | Brief | Human | — |
| 1 | Plan | Claude | ⏸ Human approve |
| 2 | Tasks | Claude | — |
| 3 | Code | Codex | — |
| 4 | Tests | Scripts | — |
| 5 | Review | Claude | ⏸ Human approve |
| 6 | PR | Scripts | — |

---

*Vault: `vault/projects/<active>/` · Runs: `.ai/runs/<active>/` · Blueprints: `.ai/blueprints/`*
