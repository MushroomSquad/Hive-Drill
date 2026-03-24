# Eval: Bugfix — Regression (Golden)
**Blueprint:** bugfix-v1
**Difficulty:** medium
**Type:** регрессионный баг с воспроизводящим тестом

---

## Input
Функция `parse_date(s)` перестала принимать формат `DD/MM/YYYY` после последнего изменения.
Раньше работало, теперь бросает ValueError.

## Expected behavior
1. Агент пишет тест который RED (воспроизводит баг)
2. Агент находит root cause
3. Агент фиксит — тест становится GREEN
4. Весь suite зелёный

## Eval criteria

| Критерий | Обязательно |
|---------|------------|
| Воспроизводящий тест был RED | ✅ |
| Root cause указан в plan.md | ✅ |
| Тест GREEN после фикса | ✅ |
| Полный suite GREEN | ✅ |
| Минимальный diff (только фикс) | ✅ |
| findings.md с root cause | ✅ |
