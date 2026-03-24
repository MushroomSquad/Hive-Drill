# Definition of Done — Детальные критерии

## По типу задачи

### Feature
- [ ] Код написан, все тесты проходят
- [ ] Новая логика покрыта тестами (unit / integration)
- [ ] `scripts/ai-check.sh` зелёный
- [ ] `brief.md`, `plan.md`, `tasks.yaml`, `verification.md`, `pr-body.md` заполнены
- [ ] Нет TODO без TICKET-ID
- [ ] CHANGELOG обновлён (если поведение изменилось)
- [ ] Нет secrets в коде или коммитах

### Bug fix
- [ ] Воспроизводящий тест написан **до** фикса
- [ ] Тест проходит **после** фикса
- [ ] Root cause задокументирован в `findings.md`
- [ ] Риск регрессии оценён
- [ ] `scripts/ai-check.sh` зелёный

### Refactor
- [ ] Поведение не изменилось (тесты до = тесты после)
- [ ] Метрики сложности не выросли (если измеряются)
- [ ] Нет нового публичного API без документации
- [ ] `scripts/ai-check.sh` зелёный

### PR Review
- [ ] Все P0 issues задокументированы
- [ ] `findings.md` заполнен структурированно
- [ ] Reviewer points разбиты на: blocker / suggestion / nit
- [ ] Финальное мнение: approve / request-changes / needs-discussion

### Release
- [ ] Все запланированные задачи в done
- [ ] `scripts/ai-check.sh` на release branch зелёный
- [ ] CHANGELOG заполнен
- [ ] Migration guide (если есть breaking changes)
- [ ] Rollback plan задокументирован

## Общие правила для всех типов

| Правило | Обязательно |
|---------|------------|
| Нет hardcoded secrets | ✅ всегда |
| Нет console.log / print отладки | ✅ всегда |
| Нет закомментированного кода | ✅ всегда |
| Worktree убран после PR | ✅ после merge |
| Артефакты в `.ai/runs/` | ✅ всегда |
