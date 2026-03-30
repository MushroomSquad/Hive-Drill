# Skill: Module Migration
**Owner:** Claude Code (planning P0/P1) + Codex (execution P1)
**When to use:** Move/rename module, switch to new dependency, extract to separate package.

---

## Task
Safely migrate module with full behavior preservation.

## Pre-flight checklist (MANDATORY before start)
- [ ] Tests for migrated code exist and green
- [ ] Clear who uses module (grep / IDE references)
- [ ] Rollback plan exists (branch, feature flag, or quick revert)
- [ ] Scope defined: what to migrate, what NOT to touch

## Steps

### 1. Map dependencies
```bash
# Find all module users
grep -r "import.*<module>" src/ tests/
grep -r "from <module>" src/ tests/
```
Record in `migration-map.md`.

### 2. Plan migration
Choose strategy:
- **Strangler Fig** (gradually): new module → redirect → delete old
- **Big Bang** (atomic): create new → switch all → delete old
- **Alias/Re-export** (compatible): old path = alias to new

### 3. Execute (step by step)

```
Step A: Create new location / new module
  → ./scripts/ai-check.sh  (tests PASS)

Step B: Move file / class one by one
  → ./scripts/ai-check.sh  (tests PASS after each)

Step C: Update all imports
  → ./scripts/ai-check.sh  (tests PASS)

Step D: Delete old module
  → ./scripts/ai-check.sh  (tests PASS)
```

### 4. Verify
- [ ] All tests green
- [ ] No remaining old path references (`grep` clean)
- [ ] No breaking change in public API (if module is public)

## Output
```
.ai/runs/<TASK-ID>/
  migration-map.md
  plan.md
  verification.md
```

## Escalation
- If module used in > 20 places → split into multiple tasks
- If public API → need deprecation strategy, not instant removal
