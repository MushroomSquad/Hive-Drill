# Skill: Release Checklist
**Owner:** Codex (gathering) + Claude Code (security sweep)
**When to use:** Before each release. Automates routine check part.

---

## Task
Run full pre-release checklist and produce go/no-go report.

## Steps

### 1. Automated sweep
```bash
./scripts/ai-check.sh --full 2>&1 | tee .ai/runs/<RUN_ID>/release-sweep.txt
```

### 2. Code hygiene check
```bash
# TODO without TICKET-ID
grep -r "TODO" src/ | grep -v "TODO(TICKET" | grep -v "TODO: n/a"

# Debug code
grep -r "console.log\|debugger\|pdb.set_trace\|breakpoint()" src/

# Hardcoded secrets (basic scan)
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
- [ ] Version updated in package.json / pyproject.toml / go.mod
- [ ] Git tag planned

### 5. CHANGELOG check
- [ ] CHANGELOG.md updated for this release
- [ ] All breaking changes documented

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
