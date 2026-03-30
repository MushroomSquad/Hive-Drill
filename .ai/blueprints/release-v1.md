# Blueprint: Release Hardening — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Prepare and verify release: final sweep, CHANGELOG, migration guide, rollback plan.

## Roles

| Stage | Owner |
|--------|---------|
| Release brief | Human / Cursor |
| Automated sweep | scripts |
| Security review | Claude Code (P0) |
| CHANGELOG | Codex |
| Rollback plan | Claude Code |
| Release sign-off | Human |

---

## Stage 0: Release brief

```markdown
# Brief: RELEASE-<version>

## Version
<semver>

## Planned changes
- ...

## Breaking changes
- [ ] No
- [ ] Yes: <description>

## Migration required
- [ ] No
- [ ] Yes: <description>

## Rollback plan
<how to rollback if something goes wrong>

## Release window
<when to deploy>

## Go/No-go criteria
- [ ] ...
```

---

## Stage 1: Pre-release sweep

```bash
./scripts/ai-check.sh --full
```

Additional checks:
- [ ] All planned tasks in done
- [ ] No open P0 bugs in this milestone
- [ ] No TODO without TICKET-ID in code
- [ ] No temporary debug code
- [ ] Version updated (package.json / pyproject.toml / etc.)

---

## Stage 2: Security sweep

**Owner:** Claude Code (always P0)

```markdown
# Security findings: RELEASE-<version>

## SAST results
...

## Dependency audit
...

## Auth/authz review
...

## Secrets scan
...

## Verdict: GO / NO-GO
```

---

## Stage 3: CHANGELOG

**Owner:** Codex
**Format:** Keep a Changelog (https://keepachangelog.com)

```markdown
## [<version>] - <date>

### Added
- ...

### Changed
- ...

### Deprecated
- ...

### Removed
- ...

### Fixed
- ...

### Security
- ...
```

---

## Stage 4: Rollback plan

**Owner:** Claude Code

```markdown
# Rollback Plan: RELEASE-<version>

## Trigger conditions
When to rollback (metrics, errors, threshold).

## Steps
1. ...
2. ...

## Data rollback
Is backward migration needed?

## Estimated time
How long will rollback take.

## Contact
Who makes rollback decision.
```

---

## Stage 5: Sign-off

Checklist for human:
- [ ] Security sweep: PASS
- [ ] All tests: PASS
- [ ] CHANGELOG filled
- [ ] Rollback plan exists
- [ ] Release window agreed
- [ ] Deploy plan understood by team

---

## Artifacts

```
.ai/runs/RELEASE-<version>/
  brief.md
  security-findings.md
  verification.md
  rollback-plan.md
  CHANGELOG-<version>.md
```

---

## Writing standards

After writing each document — `/humanize`. CHANGELOG — especially important. See BASE.md § Writing standards.
