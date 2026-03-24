# Skill: Module Migration
**Owner:** Claude Code (планирование P0/P1) + Codex (исполнение P1)
**When to use:** Перемещение/переименование модуля, переход на новую зависимость, извлечение в отдельный пакет.

---

## Task
Безопасно мигрировать модуль с полным сохранением поведения.

## Pre-flight checklist (ОБЯЗАТЕЛЬНО перед началом)
- [ ] Тесты для мигрируемого кода есть и зелёные
- [ ] Понятно, кто использует модуль (grep / IDE references)
- [ ] Есть rollback plan (ветка, feature flag, или быстрый revert)
- [ ] Scope определён: что мигрируем, что НЕ трогаем

## Steps

### 1. Map dependencies
```bash
# Найти всех пользователей модуля
grep -r "import.*<module>" src/ tests/
grep -r "from <module>" src/ tests/
```
Зафиксировать в `migration-map.md`.

### 2. Plan migration
Выбрать стратегию:
- **Strangler Fig** (постепенно): новый модуль → перенаправить → удалить старый
- **Big Bang** (атомарно): создать новое → переключить всех → удалить старое
- **Alias/Re-export** (совместимость): старый путь = алиас к новому

### 3. Execute (step by step)

```
Step A: Создать новое место / новый модуль
  → ./scripts/ai-check.sh  (тесты PASS)

Step B: Перенести по одному файлу / классу
  → ./scripts/ai-check.sh  (тесты PASS после каждого)

Step C: Обновить все импорты
  → ./scripts/ai-check.sh  (тесты PASS)

Step D: Удалить старый модуль
  → ./scripts/ai-check.sh  (тесты PASS)
```

### 4. Verify
- [ ] Все тесты зелёные
- [ ] Нет оставшихся ссылок на старый путь (`grep` clean)
- [ ] Нет breaking change в публичном API (если модуль публичный)

## Output
```
.ai/runs/<TASK-ID>/
  migration-map.md
  plan.md
  verification.md
```

## Escalation
- Если модуль использует > 20 мест → разбить на несколько задач
- Если публичный API → нужна deprecation-стратегия, не мгновенный снос
