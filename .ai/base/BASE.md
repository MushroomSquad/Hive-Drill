# BASE — Канон проекта

Этот файл — единственный источник истины о правилах проекта.
`AGENTS.md` и `CLAUDE.md` ссылаются на него. Не дублируй правила из BASE.md в других файлах.

---

## Project mission

> Заполни: что производит этот проект, кому и зачем.

## Architecture constraints

> Заполни: какие архитектурные решения уже приняты и не пересматриваются.

- [ ] TODO: список сервисов / модулей
- [ ] TODO: граница зон ответственности
- [ ] TODO: что нельзя трогать без явного решения команды

## Tech stack

| Компонент | Технология | Версия |
|-----------|-----------|--------|
| TODO      | TODO      | TODO   |

## Build & test commands

```bash
# Заменить на реальные команды проекта
# npm run lint
# npm run typecheck
# npm test
# make check
```

## Coding standards

- Язык нового кода: TODO (выбери: Python / TypeScript / Go / etc.)
- Именование: TODO (snake_case / camelCase / etc.)
- Минимальное покрытие тестами: TODO %
- Обязательный linter: TODO
- Форматтер: TODO

## What agents may NOT do without explicit approval

- Изменять схему БД
- Менять публичный API (breaking changes)
- Удалять данные в production
- Изменять CI/CD пайплайны
- Коммитить secrets, ключи, credentials
- Amend опубликованных коммитов

## Definition of done

Задача считается выполненной, когда:
- [ ] `scripts/ai-check.sh` проходит без ошибок
- [ ] Юнит-тесты написаны / обновлены
- [ ] `verification.md` заполнен
- [ ] `pr-body.md` готов
- [ ] Нет закомментированного кода
- [ ] Нет hardcoded secrets

## Review rules

1. Каждый PR должен иметь `pr-body.md` с мотивацией изменений.
2. Breaking changes требуют явного обозначения в PR.
3. Изменения в `.ai/base/BASE.md` требуют ревью человека, не агента.

## Escalation policy

| Ситуация | Действие |
|---------|---------|
| Security issue найден | Стоп, создать findings.md, эскалировать |
| Неясная причина бага | Стоп, написать диагноз, спросить человека |
| Требуется изменить схему БД | Стоп, написать migration plan, спросить |
| Diff > 500 строк неожиданно | Проверить scope, возможно нужно разбить |
