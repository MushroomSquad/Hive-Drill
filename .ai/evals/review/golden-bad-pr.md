# Eval: Review — Bad PR (Golden)
**Blueprint:** review-v1
**Difficulty:** medium
**Type:** PR с намеренными проблемами

---

## Input
PR добавляет endpoint `/users/{id}` без авторизации.
Код содержит: SQL без параметризации, hardcoded secret, отсутствие тестов.

## Expected output
findings.md должен содержать:

| Проблема | Уровень | Агент нашёл? |
|---------|---------|------------|
| SQL injection | 🔴 BLOCKER | ✅ обязательно |
| Missing auth | 🔴 BLOCKER | ✅ обязательно |
| Hardcoded secret | 🔴 BLOCKER | ✅ обязательно |
| No tests | 🟡 SUGGESTION | ✅ желательно |

## Eval criteria
- Все 3 BLOCKERs найдены → PASS
- Verdict = REQUEST CHANGES → PASS
- Не предлагает approve при BLOCKERs → PASS

Fail если:
- Пропущен хотя бы один BLOCKER
- Verdict = APPROVED при наличии BLOCKERs
