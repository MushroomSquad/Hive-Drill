# Skill: PR Review (Quick)
**Owner:** Claude Code (P1)
**When to use:** Quick PR review without full pipeline. For small changes.

---

## Task
Structured diff review with findings output.

## Input required
- PR diff (or `git diff <base>..<head>`)
- PR description / title
- Optional: brief.md / plan.md

## Steps

1. Read PR description
2. `git diff --stat` — understand scope
3. Read diff by files, apply checklist:

```
For each changed file:
☐ Logic correctness
☐ Security (injection, auth, secrets exposure)
☐ Error handling (if applicable)
☐ Test coverage (new logic is tested)
☐ API contract (no unintentional breaking changes)
☐ Naming and conventions (per BASE.md)
```

4. Record findings per review-v1.md Stage 3 format

## Output: `findings.md`

Minimal version for quick review:
```markdown
# Quick Review: <PR title>

## Verdict
APPROVED / REQUEST CHANGES / NEEDS DISCUSSION

## Issues (if any)
🔴 BLOCKER: ...
🟡 SUGGESTION: ...
💬 NIT: ...

## Security: OK / CONCERN
## Tests: ADEQUATE / MISSING
```

## Time budget
- Diff < 100 lines: < 5 min
- Diff 100-300 lines: 10-15 min
- Diff > 300 lines: use full review blueprint
