# Skill: Test Triage
**Owner:** Codex (P2 → local-fast)
**When to use:** Тест suite падает, нужно быстро классифицировать что и почему.

---

## Task
Запустить тесты, классифицировать провалы, предложить план фикса.

## Steps

1. Запустить тесты и собрать вывод:
   ```bash
   <test_command> 2>&1 | tee .ai/runs/<RUN_ID>/test-output.txt
   ```

2. Классифицировать каждый провал:
   - `REGRESSION` — работало раньше, сломалось недавно
   - `NEW_FAILURE` — новый тест, никогда не проходил
   - `FLAKY` — непостоянный результат
   - `ENV_ISSUE` — проблема окружения, не кода

3. Для каждого REGRESSION найти: последний коммит где было зелёно (`git bisect` или `git log`).

4. Выход: `test-triage.md`

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
- Если REGRESSION в security-related тесте → P0, эскалировать
- Если > 20 одновременных регрессий → возможно системная проблема, эскалировать
