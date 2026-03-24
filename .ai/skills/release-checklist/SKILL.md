# Skill: Release Checklist
**Owner:** Codex (сбор) + Claude Code (security sweep)
**When to use:** Перед каждым релизом. Автоматизирует рутинную часть проверки.

---

## Task
Прогнать полный pre-release checklist и сформировать go/no-go отчёт.

## Steps

### 1. Automated sweep
```bash
./scripts/ai-check.sh --full 2>&1 | tee .ai/runs/<RUN_ID>/release-sweep.txt
```

### 2. Code hygiene check
```bash
# TODO без TICKET-ID
grep -r "TODO" src/ | grep -v "TODO(TICKET" | grep -v "TODO: n/a"

# Debug code
grep -r "console.log\|debugger\|pdb.set_trace\|breakpoint()" src/

# Hardcoded secrets (базовый scan)
grep -rE "(password|secret|token|api_key)\s*=\s*['\"][^'\"]{8,}" src/
```

### 3. Dependency audit
```bash
# npm
npm audit --audit-level=high

# Python
pip-audit || safety check

# Go
govulncheck ./...
```

### 4. Version bump check
- [ ] Версия обновлена в package.json / pyproject.toml / go.mod
- [ ] Git tag запланирован

### 5. CHANGELOG check
- [ ] CHANGELOG.md обновлён для этого релиза
- [ ] Все breaking changes задокументированы

## Output: `release-checklist.md`

```markdown
# Release Checklist: v<version>

## Automated checks
- lint: PASS / FAIL
- tests: PASS / FAIL (N passed)
- security scan: PASS / ISSUES

## Code hygiene
- TODO cleanup: CLEAN / N items
- Debug code: CLEAN / FOUND
- Secrets scan: CLEAN / ALERT

## Dependencies
- Audit: PASS / HIGH/CRITICAL vulns found

## Versioning
- Version bumped: YES / NO
- CHANGELOG updated: YES / NO

## GO / NO-GO: GO | NO-GO
Reason (if NO-GO): ...
```
