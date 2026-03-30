# Skill: Test Triage
**Owner:** Codex (P2 → local-fast)
**When to use:** Test suite fails, need to quickly classify what and why.

---

## Task
Run tests, classify failures, propose fix plan.

## Steps

1. Run tests and collect output:
   ```bash
   <test_command> 2>&1 | tee .ai/runs/<RUN_ID>/test-output.txt
   ```

2. Classify each failure:
   - `REGRESSION` — used to work, broke recently
   - `NEW_FAILURE` — new test, never passed
   - `FLAKY` — inconsistent results
   - `ENV_ISSUE` — environment problem, not code

3. For each REGRESSION find: last commit where it was green (`git bisect` or `git log`).

4. Output: `test-triage.md`

## Output format

```markdown
# Test Triage: <date>

## Summary
- Total failed: N
- REGRESSION: N
- NEW_FAILURE: N
- FLAKY: N
- ENV_ISSUE: N

## Details

### REGRESSION: <test name>
File: `tests/...`
Since commit: <hash> (<date>)
Likely cause: ...
Estimated fix effort: S / M / L

### ...

## Recommended actions
1. Fix first: ...
2. Then: ...
```

## Escalation
- If REGRESSION in security-related test → P0, escalate
- If > 20 simultaneous regressions → possible systemic issue, escalate
