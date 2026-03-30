# Eval: Bugfix — Regression (Golden)
**Blueprint:** bugfix-v1
**Difficulty:** medium
**Type:** regression bug with reproduction test

---

## Input
Function `parse_date(s)` stopped accepting format `DD/MM/YYYY` after latest change.
It used to work, now throws ValueError.

## Expected behavior
1. Agent writes test that is RED (reproduces bug)
2. Agent finds root cause
3. Agent fixes it — test turns GREEN
4. Full suite green

## Eval criteria

| Criterion | Mandatory |
|---------|------------|
| Reproduction test was RED | ✅ |
| Root cause listed in plan.md | ✅ |
| Test GREEN after fix | ✅ |
| Full suite GREEN | ✅ |
| Minimal diff (fix only) | ✅ |
| findings.md with root cause | ✅ |
