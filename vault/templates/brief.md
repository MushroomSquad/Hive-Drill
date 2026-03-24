---
task_id: <!-- FILL: e.g. FEAT-001 -->
type: feature
# type options: feature | bugfix | refactor | review
priority: p1
# priority options: p0 (critical) | p1 (high) | p2 (normal) | p3 (low)
status: draft
# Change to "ready" when brief is complete, then run: just go <task_id>
created: <!-- FILL: YYYY-MM-DD -->
owner: <!-- FILL: your name or handle -->
---

# Brief: <!-- FILL: short human-readable title -->

## Goal

<!-- FILL: What needs to be done and why? What problem does this solve?
     Be specific. One paragraph is enough. -->

## Scope

### In scope
- <!-- FILL: list what IS included -->
-

### Out of scope
- <!-- FILL: list what is explicitly NOT included -->
-

## Constraints

- <!-- FILL: technical constraints, deadlines, dependencies, forbidden approaches -->
-

## Affected modules

<!-- FILL: List files, packages, services, APIs that will likely change -->

| Module / File | Change type | Notes |
|---|---|---|
| `path/to/file` | modify / add / delete | <!-- why --> |

## Risks

<!-- FILL: What could go wrong? What are the unknowns? -->

- **Risk**: <!-- describe risk --> — **Mitigation**: <!-- how to handle -->
-

## Acceptance criteria

<!-- FILL: When is this task DONE? Make each item testable. -->

- [ ] <!-- criterion 1 -->
- [ ] <!-- criterion 2 -->
- [ ] <!-- criterion 3 -->

---

> **Next step**: Change `status: draft` → `status: ready`, then run:
> ```
> just go <!-- FILL: task_id here -->
> ```
