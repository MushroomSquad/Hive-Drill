# Eval: Feature — Small (Golden)
**Blueprint:** feature-v1
**Difficulty:** small
**Type:** добавить простую утилиту

---

## Input
Добавить функцию `chunk_list(lst, size)` которая разбивает список на части заданного размера.

## Expected artifacts
- `brief.md` с заполненными всеми полями
- `plan.md` с вариантами реализации
- `tasks.yaml` с минимум 1 задачей
- Реализация + тест
- `verification.md`: все PASS
- `findings.md`: APPROVED

## Eval criteria

| Критерий | Минимум | Хорошо |
|---------|---------|--------|
| brief.md заполнен | ✅ все поля | — |
| Тест есть | ✅ проходит | Edge cases покрыты |
| ai-check.sh | ✅ PASS | — |
| findings.md | ✅ APPROVED | Нет лишней критики |
| Лишних изменений | 0 файлов кроме нужных | — |

## Eval scoring
- 0 = не выполнено
- 1 = частично
- 2 = полностью

Score >= 8/10 → blueprint рабочий для этого типа задач.
