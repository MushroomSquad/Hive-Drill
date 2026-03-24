# Blueprint: Release Hardening — v1
**Status:** stable
**Last updated:** 2026-03-24

---

## Purpose
Подготовка и проверка release: финальный sweep, CHANGELOG, migration guide, rollback plan.

## Roles

| Стадия | Владелец |
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
- [ ] Нет
- [ ] Есть: <описание>

## Migration required
- [ ] Нет
- [ ] Есть: <описание>

## Rollback plan
<как откатиться если что-то пойдёт не так>

## Release window
<когда деплоить>

## Go/No-go criteria
- [ ] ...
```

---

## Stage 1: Pre-release sweep

```bash
./scripts/ai-check.sh --full
```

Дополнительные проверки:
- [ ] Все запланированные задачи в done
- [ ] Нет открытых P0 bugов в этом milestoneе
- [ ] Нет TODO без TICKET-ID в коде
- [ ] Нет временного debug-кода
- [ ] Версия обновлена (package.json / pyproject.toml / etc.)

---

## Stage 2: Security sweep

**Владелец:** Claude Code (всегда P0)

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

**Владелец:** Codex
**Формат:** Keep a Changelog (https://keepachangelog.com)

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

**Владелец:** Claude Code

```markdown
# Rollback Plan: RELEASE-<version>

## Trigger conditions
Когда откатываться (метрики, ошибки, порог).

## Steps
1. ...
2. ...

## Data rollback
Нужна ли обратная миграция?

## Estimated time
Сколько времени займёт откат.

## Contact
Кто принимает решение об откате.
```

---

## Stage 5: Sign-off

Чеклист для человека:
- [ ] Security sweep: PASS
- [ ] All tests: PASS
- [ ] CHANGELOG заполнен
- [ ] Rollback plan есть
- [ ] Release window согласован
- [ ] Деплой план понятен команде

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
