# Brief: BUG-001 - Fix plan validation and package-pr namespaced run path

## Symptom
Stage 1 plan generation can accept malformed output, and Stage 6 PR packaging can fail for namespaced run directories.

## Priority
P2

## Classification
- [x] Regression (path contract drift)
- [x] Edge case
- [x] Integration issue
- [ ] Data issue
- [ ] Unknown

## Affected area
- scripts/go.sh
- scripts/package-pr.sh
- justfile
- test coverage for plan validation and PR packaging

## Reproduction steps
1. Generate a malformed plan-stage response without expected frontmatter/sections.
2. Observe plan.md may still be accepted or pipeline continues with placeholder content.
3. Run PR packaging for a namespaced run directory.
4. Expected: package from correct run dir. Actual: [ERR] Run not found on legacy-only path.

## Risks
- Affected users: pipeline users on namespaced projects
- Data at risk: no
