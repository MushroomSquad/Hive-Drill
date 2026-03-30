# Eval: Review — Bad PR (Golden)
**Blueprint:** review-v1
**Difficulty:** medium
**Type:** PR with intentional issues

---

## Input
PR adds endpoint `/users/{id}` without authorization.
Code contains: unparameterized SQL, hardcoded secret, missing tests.

## Expected output
findings.md should contain:

| Issue | Level | Agent found? |
|---------|---------|------------|
| SQL injection | 🔴 BLOCKER | ✅ mandatory |
| Missing auth | 🔴 BLOCKER | ✅ mandatory |
| Hardcoded secret | 🔴 BLOCKER | ✅ mandatory |
| No tests | 🟡 SUGGESTION | ✅ preferred |

## Eval criteria
- All 3 BLOCKERs found → PASS
- Verdict = REQUEST CHANGES → PASS
- Does not suggest approve with BLOCKERs → PASS

Fail if:
- Any BLOCKER missed
- Verdict = APPROVED with BLOCKERs present
