Найди способ объединить codex, warp, cursor Claude code В Одну рабочую систему 

Соберу это как единый дев-оркестр: проверю, какие у Codex, Warp, Cursor и Claude Code сейчас есть реальные точки стыковки, и предложу рабочую схему без магии и фантомных кнопок. Буду исходить из практичной цели: один проект, один терминал-контур, один контекст, несколько агентов под разные роли.

Нашёл главное: общий клей между этими штуками не “интеграция кнопка-в-кнопку”, а MCP + общие project rules + один git/worktree-контур. Warp уже прямо позиционирует себя как терминал, где можно запускать Codex и Claude Code рядом, а Cursor и Codex умеют делить конфиг/MCP в редакторе.

Да. И лучший способ здесь не пытаться сварить один монолитный комбайн, а собрать единую агентную систему из 4 ролей:

Cursor = кабина пилота
Warp = диспетчерская терминала
Codex = быстрый исполнитель кода
Claude Code = архитектор, ревьюер и длинный мыслитель
MCP = общая шина инструментов и контекста

Это не фантазия на кофейной гуще: Codex умеет работать в CLI, IDE и через MCP; его IDE extension официально работает в Cursor и делит конфиг с CLI. Cursor поддерживает MCP, rules, hooks, plugins, subagents и cloud agents. Claude Code доступен в терминале и IDE, ставится и в Cursor, поддерживает MCP, CLAUDE.md, hooks и subagents. Warp прямо продвигает запуск Codex и Claude Code из одного терминального окружения, плюс у него есть local/cloud agents и MCP.
Самая жизнеспособная схема
1. Сделай Cursor главным UI

Открой проект в Cursor и держи там основную редактуру, diff-review, чат и контекст по файлам. Сюда же ставь оба расширения: Codex и Claude Code. У OpenAI Codex extension официально работает в Cursor, а Anthropic даёт установку Claude Code и для Cursor тоже. Это уже превращает Cursor в одну редакторскую “рубку”, где два разных мозга сидят в одном кресле.
2. Используй Warp как внешний оркестратор

Warp пусть будет не “ещё одним терминалом”, а операционным центром. В одной вкладке держишь dev server и тесты, во второй запускаешь Codex CLI, в третьей Claude Code CLI. Warp официально поддерживает сценарий, где рядом используются Claude Code и Codex, а его local/cloud agents дают второй слой автоматизации поверх ручной работы.
3. Раздели роли, иначе будет агентный базар

Самая рабочая раскладка такая:

    Claude Code: планирование, архитектура, сложный рефакторинг, обзор кода, объяснение системы

    Codex: быстрое внесение изменений, генерация кода, фиксы, тесты, рутинные задачи

    Cursor agent/subagents: локальная навигация по проекту, мелкие правки, быстрые вопросы по контексту

    Warp/Oz: запуск фоновых сценариев, триггеры, повторяемые агентные пайплайны

Эта схема совпадает с сильными сторонами инструментов по их документации: Cursor заточен под editor-agent workflow, Claude Code под agentic coding с hooks/subagents/tooling, Codex под CLI/IDE coding agent, Warp под агентный terminal/orchestration layer.
Что сделать общим для всех четырёх
1. Одна шина инструментов: MCP

Это главный клей. Codex поддерживает MCP в CLI и IDE, Cursor поддерживает MCP, Claude Code поддерживает MCP, Warp local agents тоже работают с MCP. Значит, GitHub, Jira/Linear, Postgres, документацию, браузер, Figma, внутренние API и т.п. надо подключать не отдельно в голову каждого агента, а через один набор MCP-серверов.

Практически это означает:
подними один стек MCP-серверов для проекта и зарегистрируй его во всех клиентах.

Минимальный набор обычно такой:

    GitHub

    Jira или Linear

    Docs/knowledge

    Browser/Playwright

    PostgreSQL

    Filesystem/Repo tools

2. Один источник проектной памяти

Здесь есть тонкий момент:
Codex и Cursor понимают AGENTS.md, а Claude Code живёт через CLAUDE.md. Cursor docs прямо говорят, что AGENTS.md можно использовать как простой способ задавать инструкции; Codex тоже читает AGENTS.md перед началом работы; Claude Code использует CLAUDE.md как постоянную память проекта.

Поэтому не стоит вручную поддерживать три разных истины. Лучше так:

docs/ai/BASE.md        # канон
AGENTS.md              # короткая обвязка для Codex/Cursor
CLAUDE.md              # короткая обвязка для Claude
.cursor/rules/...      # минимальные editor-specific правила

Смысл:

    BASE.md хранит главные правила проекта

    AGENTS.md и CLAUDE.md почти не содержат логики, а ссылаются на BASE.md

    .cursor/rules оставляешь тонким слоем, только для editor-specific поведения

Пример канонической структуры:

# docs/ai/BASE.md

## Project mission
...

## Architecture constraints
...

## Coding standards
...

## Allowed commands
- npm test
- npm run lint
- npm run typecheck

## Definition of done
- tests passed
- lint passed
- no secrets
- changelog updated if behavior changed

AGENTS.md:

Read `docs/ai/BASE.md` first.
Default mode: implement changes conservatively.
Always run the validation commands before proposing completion.

CLAUDE.md:

Read `docs/ai/BASE.md` first.
Default mode: plan first, then implement in small verified steps.
Prefer architectural explanations and risk notes.

3. Общий слой проверки через hooks/scripts

Cursor поддерживает hooks, Claude Code поддерживает hooks, а Codex хорошо стыкуется с правилами, skills и общими скриптами проекта. Поэтому проверки лучше выносить в обычные repo-скрипты, а не прятать их в головы агентов.

Сделай один скрипт:

#!/usr/bin/env bash
set -euo pipefail

npm run lint
npm run typecheck
npm test

Например scripts/ai-check.sh.

Тогда:

    Claude hook вызывает scripts/ai-check.sh

    Cursor hook вызывает scripts/ai-check.sh

    Codex в AGENTS.md получает правило: “после изменений гоняй scripts/ai-check.sh”

Так ты получаешь одинаковый критерий истины для всех.
4. Одна стратегия параллельной работы: git worktrees

Для нескольких агентов один и тот же working tree быстро превращается в драку стульями. Нормальная схема такая:

    main или develop остаётся чистым

    под каждую агентную ветку отдельный worktree

    Claude делает план/рефактор в одной ветке

    Codex пилит реализацию в другой

    Cursor используется для сравнения diff и сборки финального решения

Это уже моя рекомендация как архитектурный паттерн. Документация Claude Code и Codex прямо упоминает работу с worktrees/локальными окружениями, так что подход здесь естественный.
Сборка “без боли”, которую я бы советовал
Базовый режим, без лишней инженерной акробатики

Это мой главный совет.

    Cursor как основной редактор
    Поставь туда Codex extension и Claude Code extension.

    Warp как терминальный центр
    Три панели:

        app/test runner

        codex

        claude

    Единый MCP-набор
    Подключи одинаковые MCP-серверы в Cursor, Codex и Claude Code. Warp тоже может использовать MCP для local agents.

    Один канон инструкций

        docs/ai/BASE.md

        AGENTS.md

        CLAUDE.md

    Один валидатор

        scripts/ai-check.sh

    Одна веточная дисциплина

        отдельный worktree на агент

Режим “по-взрослому”, если хочешь склеить ещё сильнее

Тут начинается уже инженерный джаз 🎛️

OpenAI официально позволяет запускать Codex как MCP server через codex mcp-server, а Cursor, Claude Code и Warp умеют подключаться к MCP servers. Значит, теоретически можно сделать Codex инструментом внутри другой агентной среды: например, чтобы Claude Code планировал и вызывал Codex как исполнителя, или чтобы Cursor agent получал доступ к Codex как внешнему tool. OpenAI также показывает сценарий, где Codex используется через Agents SDK как MCP server.

Но тут честно:
официальной end-to-end инструкции именно для связки Cursor + Warp + Claude Code + Codex как единого кросс-вендорного супер-стека я не нашёл. По протоколу и возможностям это выглядит реализуемо, но я бы считал это advanced/experimental режимом.
Мой итог

Самая адекватная формула такая:

Один редактор: Cursor
Один терминальный центр: Warp
Два специализированных агента: Codex + Claude Code
Один клей: MCP
Одна память проекта: BASE.md → AGENTS.md + CLAUDE.md
Один валидатор: repo scripts + hooks
Одна дисциплина параллельности: git worktrees

Это уже не “набор разрозненных игрушек”, а вполне взрослая рабочая система.

Если дашь мне твою ОС и стек проекта, я соберу тебе готовый blueprint: структуру файлов, шаблоны AGENTS.md / CLAUDE.md, список MCP-серверов и стартовый workflow именно под твой Python/TS/monorepo.

Давай на основе первого варианта правдлподобный и очень подробный воркфлоу
В идеале если есть способ делать пайпланый и работать с этим как с пайплайн ами
Создавать их годами типа блюпринтов было бы прекрасно 

Собираю это уже не как “связку тулов”, а как производственную линию: роли, этапы, handoff, правила, артефакты и шаблоны пайплайнов. Заодно проверю, что из официальных возможностей реально можно опереть на docs, а что лучше обозначить как инженерный паттерн, а не встроенную фичу.

Пазл сложился: нативного “единого pipeline engine на четверых” у них нет, но есть очень правдоподобная и долговечная схема. Её стержень такой: blueprint как файл в репозитории, agents как исполнители ролей, MCP как инструментальная шина, а запуск пайплайнов через обычный CLI/CI слой.

Да. Ниже не “красивая идея”, а правдоподобная производственная схема, которую реально можно тянуть годами и постепенно шлифовать как набор блюпринтов.

Сразу важная оговорка: у Codex + Warp + Cursor + Claude Code нет одной штатной кнопки “Build Pipeline Universe”. Зато у них есть все нужные кирпичи: у Cursor есть rules, hooks, subagents и cloud agents; у Claude Code есть IDE/CLI, CLAUDE.md, hooks, subagents и MCP; у Codex есть расширение для Cursor, общая конфигурация CLI/IDE, AGENTS.md, skills, MCP и режим MCP server; у Warp/Oz есть local/cloud agents, CLI/API/SDK для запуска из scripts и CI, а сам Warp умеет работать с Codex и Claude Code как с first-class CLI agents. Из этого уже собирается единая система без скотча и молитв.
Что именно мы строим

Не “один супер-агент”, а операционную систему разработки из 5 слоёв:

    UI-слой: Cursor

    Терминальный и orchestration-слой: Warp / Oz

    Агенты ролей: Codex и Claude Code

    Tool-bus: MCP

    Постоянные blueprint-файлы в репозитории

Ключевая мысль:
pipeline живёт не в голове модели, а в git-репозитории.
Модели только исполняют роли внутри этого pipeline.
Роли в системе

Я бы закрепил роли так:

Cursor
Главная кабина. Тут идёт навигация по коду, diff-review, ручная коррекция, запуск editor-agent задач, быстрые подзадачи и финальная сборка результата. Cursor rules и subagents здесь работают как тонкий слой дисциплины над редактором.

Claude Code
Архитектор и длинный мыслитель. Он лучше всего подходит для:

    декомпозиции задачи

    архитектурного плана

    риск-анализа

    сложного рефакторинга

    поиска тонких причин багов

    финального narrative-review

У Claude Code для этого есть CLAUDE.md, hooks, subagents, IDE/CLI, git/worktree workflows и MCP.

Codex
Исполнитель и ускоритель. Он хорош там, где нужен быстрый инженерный проход:

    написать код по уже понятному плану

    добить тесты

    прогнать review-паттерн

    выполнить узкий skill

    встроиться в multi-agent workflow через MCP server

Codex читает AGENTS.md до начала работы, поддерживает project-scoped .codex/config.toml, skills и может быть поднят как MCP server для внешней оркестрации.

Warp / Oz
Диспетчерская и конвейерный мотор.
Локально Warp удобен как единый терминал для Codex и Claude Code. Для pipeline-режима важнее Oz CLI/API/SDK: он может запускать agents локально, в cloud, из scripts и CI/CD, а также имеет GitHub Actions интеграцию.
Главный принцип: blueprint как контракт

Каждый pipeline должен быть оформлен как versioned contract:

    что запускает pipeline

    кто его ведёт

    какие этапы

    какие артефакты обязаны появиться

    какие проверки обязательны

    что считается done

    какие правила эскалации

    какие роли выполняют Codex, Claude, Cursor, Oz

То есть не “сделай фичу”, а:

    Feature Blueprint v1

    Bugfix Blueprint v2

    Refactor Blueprint v3

    PR Review Blueprint v1

    Release Hardening Blueprint v2

Их не надо каждый раз переписывать. Они должны лежать в репозитории как долгоживущие заводские формы.
Как хранить это в репозитории

Я бы делал так:

repo/
├─ .ai/
│  ├─ base/
│  │  ├─ BASE.md
│  │  ├─ glossary.md
│  │  ├─ architecture-map.md
│  │  └─ done-criteria.md
│  ├─ blueprints/
│  │  ├─ feature-v1.md
│  │  ├─ bugfix-v1.md
│  │  ├─ refactor-v1.md
│  │  ├─ review-v1.md
│  │  └─ release-v1.md
│  ├─ skills/
│  │  ├─ test-triage/
│  │  │  └─ SKILL.md
│  │  ├─ pr-review/
│  │  │  └─ SKILL.md
│  │  └─ migrate-module/
│  │     └─ SKILL.md
│  ├─ pipelines/
│  │  ├─ feature.yaml
│  │  ├─ bugfix.yaml
│  │  └─ review.yaml
│  ├─ runs/
│  │  └─ 2026-03-21-PAY-1842/
│  │     ├─ brief.md
│  │     ├─ plan.md
│  │     ├─ tasks.yaml
│  │     ├─ findings.md
│  │     ├─ verification.md
│  │     ├─ pr-body.md
│  │     └─ retro.md
│  └─ evals/
│     ├─ feature/
│     ├─ bugfix/
│     └─ review/
├─ .codex/
│  └─ config.toml
├─ .cursor/
│  └─ rules/
├─ .claude/
│  ├─ settings.json
│  └─ skills/
├─ AGENTS.md
├─ CLAUDE.md
└─ scripts/
   ├─ ai-check.sh
   ├─ blueprint-run.sh
   ├─ plan-init.sh
   └─ package-pr.sh

Почему так:

    AGENTS.md нужен Codex как постоянная инструкция.

    CLAUDE.md Claude грузит в каждую сессию как project memory.

    Cursor agent может использовать project rules и тот же repo-context, а его CLI использует ту же rules-систему, что и редактор.

    Skills у Codex и Claude удобно использовать как переиспользуемые “мини-блюпринты” для узких повторяющихся задач.

Слой постоянной памяти

Здесь нужен порядок, иначе получится кладбище инструкций.
1. Канон

/.ai/base/BASE.md

Только самое постоянное:

    архитектурные ограничения

    команды сборки и тестов

    соглашения по коду

    что нельзя трогать

    правила review

    definition of done

2. Тонкие адаптеры

AGENTS.md и CLAUDE.md должны быть короткими, почти как роутеры:

Read .ai/base/BASE.md first.
For workflow selection, use .ai/blueprints/.
For repeated operations, prefer scripts/ and .ai/skills/.
Always produce run artifacts under .ai/runs/<run-id>/.

Так у тебя одна каноническая база, а не три конкурирующие религии.
Как выглядит сам pipeline

Нормальный pipeline должен идти по стадиям, и у каждой стадии должен быть владелец, вход, выход и критерий завершения.
Pipeline Feature v1
Stage 0. Intake

Кто: Cursor или пользователь вручную
Задача: оформить вход в структурированный brief
Выход: brief.md

Содержимое:

    цель

    scope / out-of-scope

    ограничения

    затронутые модули

    риски

    критерии готовности

Stage 1. Architectural pass

Кто: Claude Code
Задача: понять систему и выписать реалистичный план
Выход: plan.md

В plan.md:

    диагноз текущего состояния

    варианты решения

    выбранный вариант

    этапы выполнения

    риски миграции

    тестовая стратегия

    rollback strategy

Это как раз та зона, где Claude Code особенно силён: план, review плана, работа с несколькими разговорами, worktrees и IDE/CLI режим.
Stage 2. Task slicing

Кто: Claude Code или Cursor subagent
Задача: разрезать план на атомарные задачи
Выход: tasks.yaml

Пример:

run_id: 2026-03-21-PAY-1842
blueprint: feature-v1
tasks:
  - id: T1
    title: Add domain model
    owner: codex
    inputs: [brief.md, plan.md]
    outputs: [src/payments/domain.py, tests/test_domain.py]
  - id: T2
    title: Integrate service layer
    owner: codex
    outputs: [src/payments/service.py]
  - id: T3
    title: Review architecture drift
    owner: claude
    outputs: [findings.md]
  - id: T4
    title: Final integration review
    owner: cursor
    outputs: [verification.md]

Stage 3. Isolated execution

Кто: Codex и Claude в отдельных worktree
Задача: выполнять задачи параллельно, не пихаясь локтями
Выход: код + заметки + локальные diff

Claude Code прямо документирует git/worktrees для параллельной работы, и это идеально сюда ложится.

Схема:

    wt/PAY-1842-claude

    wt/PAY-1842-codex

    wt/PAY-1842-review

Важный момент:
агенты не пишут сразу в main working tree.
Каждый агент работает в своём песочном аквариуме.
Stage 4. Deterministic verification

Кто: scripts + hooks
Задача: прогнать всё, что не должно зависеть от настроения модели
Выход: verification.md

Например:

#!/usr/bin/env bash
set -euo pipefail

npm run lint
npm run typecheck
npm test

Claude hooks умеют автоматически вызывать shell/HTTP/LLM hooks на стадиях жизненного цикла, а Cursor hooks позволяют встроить кастомные скрипты в agent loop. Это именно тот слой, где проверка перестаёт быть “ну вроде норм” и становится машинной.
Stage 5. Narrative review

Кто: Claude Code
Задача: осмыслить результат как инженер, а не как компилятор
Выход: findings.md

Там фиксируется:

    не сломана ли архитектура

    нет ли лишней сложности

    что осталось техническим долгом

    какие follow-up задачи нужны

Stage 6. PR packaging

Кто: Codex или Cursor
Задача: упаковать изменения как понятный PR
Выход: pr-body.md, changelog, commit message

Codex поддерживает review workflows, а blueprint можно завязать на единый code_review.md, referenced from AGENTS.md, чтобы поведение review оставалось одинаковым между репами.
Stage 7. Retro and memory update

Кто: человек + агент
Задача: превратить уроки в постоянные улучшения
Выход: update в BASE.md, AGENTS.md, CLAUDE.md, skills или blueprint

Это критично. Иначе система каждый месяц забывает, чему научилась.
Как превратить это в настоящие blueprint-ы на годы

Вот здесь начинается самое вкусное 🍱
Правило 1. Blueprint не равен prompt

Blueprint это пакет:

    инструкция

    артефакты

    скрипты

    правила handoff

    eval-критерии

    версии

То есть:

    Markdown описывает логику

    YAML описывает этапы

    Scripts делают детерминированные вещи

    Skills учат агента повторяемому поведению

    Evals проверяют, что blueprint реально работает

OpenAI прямо продвигает skills как reusable, versioned bundles, а также описывает eval-подход для навыков.
Правило 2. Не редактируй stable blueprint бесконечно

Сделай жизненный цикл:

    draft

    beta

    stable

    legacy

Например:

    feature-v1

    feature-v2

    feature-v3

v1 остаётся воспроизводимым.
v2 появляется только когда накопилось достаточно уроков.
Правило 3. Каждый blueprint должен иметь goldens

Для каждого blueprint нужны 3-10 эталонных задач:

    маленькая фича

    сложная фича

    регрессионный баг

    рефактор без поведения

    PR review с намеренно плохим кодом

На них гоняешь изменения blueprint-а. Это уже почти “unit tests для процесса”.
Как запускать это как pipeline, а не как ритуал вручную

Есть три зрелости.
Уровень A. Repo-native, самый практичный

Самый здравый старт.

Запуск через just, make, task или shell:

just bp feature PAY-1842

Внутри:

    создаётся .ai/runs/<run-id>/

    генерится brief.md

    создаётся worktree

    запускается Claude на plan stage

    запускается Codex на exec stage

    гоняются скрипты проверки

    собирается pr-body.md

Это не “официальная фича одного вендора”, а инженерная обвязка поверх их возможностей. Зато она простая и очень живучая.
Уровень B. Warp/Oz как pipeline runner

Когда хочется, чтобы pipeline был уже не просто shell-script, а управляемый агентный запуск.

Oz CLI предназначен для запуска агентов из терминала, scripts, automated systems и CI/CD, а oz-agent-action позволяет запускать их прямо в GitHub Actions. У Oz есть разделение на local oz agent run и cloud oz agent run-cloud.

Здесь блюпринт можно запускать так:

    локально через oz agent run

    в CI через oz agent run-cloud

    по PR trigger через GitHub Actions

Это уже почти заводской конвейер.
Уровень C. Настоящий multi-agent orchestration

Самый мощный и самый инженерный уровень.

Codex можно поднять как MCP server командой codex mcp-server, а затем оркестрировать через OpenAI Agents SDK с hand-offs и traces. OpenAI прямо показывает multi-agent workflow поверх этого механизма.

То есть ты можешь построить orchestrator, где:

    главный агент читает blueprint

    Claude делает plan

    Codex исполняет конкретные code tasks через MCP

    результаты валидируются

    финальный агент собирает PR narrative

Это уже почти “pipeline engine”, только собранный тобой.
Самая реалистичная схема для долгой жизни

Я бы рекомендовал такой маршрут:
Фаза 1

Собрать repo-native blueprint system:

    BASE.md

    AGENTS.md

    CLAUDE.md

    scripts/ai-check.sh

    3 блюпринта: feature, bugfix, review

    .ai/runs/ для артефактов

Фаза 2

Добавить skills:

    test-triage

    pr-review

    module-migration

    release-checklist

У Codex и Claude skills для этого очень подходят: они задают повторяемый task-specific workflow через SKILL.md.
Фаза 3

Добавить Warp/Oz runner:

    локальный запуск

    cloud-run для тяжёлых задач

    GitHub Actions для PR review / CI fix / issue triage

Фаза 4

Добавить eval layer

    прогон блюпринтов на тестовых задачах

    score по качеству

    regression suite для пайплайнов

Мой итоговый рецепт

Если нужен правдоподобный и долговечный workflow, то он должен выглядеть так:

Blueprints в git
↓
Claude делает план и slicing
↓
Codex исполняет узкие engineering-задачи
↓
Cursor собирает, ревьювит и управляет руками
↓
Warp/Oz запускает pipeline локально или в CI
↓
Scripts/hooks проверяют детерминированную часть
↓
Retro обновляет память системы

Это уже не просто “пользоваться несколькими AI”, а строить фабрику повторяемой разработки.

Следом я могу собрать тебе конкретный starter-kit: готовые файлы BASE.md, AGENTS.md, CLAUDE.md, feature-v1.md, bugfix-v1.md, review-v1.md, плюс justfile или Taskfile.yml для запуска всего этого одной командой.

Вопрос
У всех них есть лимиты
Можно ли как то внутри задач расставлять приоритеты с Допустим переключение моделей на локальные аналогичные через air llm
А все сложные и кретичные на клауд модели по выбору выносить 

Проверю это как инженерную схему маршрутизации нагрузки: что можно делать нативно у самих инструментов, а что придётся строить своим “роутером задач”. Заодно уточню, что именно умеют по model selection, чтобы не нарисовать фантомный тумблер.

Уже видно главное: да, это можно собрать, но не как один “магический авто-роутер” внутри всех четырёх сразу. Самый гибкий путь такой: нативные переключатели моделей использовать там, где они есть, а сверху повесить свой policy-router, который решает, какую задачу кому и на какой модели отдавать.

Да, можно. Самая здравая схема тут такая: не пытаться заставить все 4 инструмента одинаково понимать “локальная vs облачная модель”, а ввести слой маршрутизации задач. Он решает, что дешёвое и рутинное уходит на local lane, а сложное, рискованное и архитектурное на cloud lane. Это хорошо ложится на реальные возможности стека: у Claude Code есть встроенная гибридная схема opusplan и настройка effort, у Codex есть профили, выбор модели и кастомные провайдеры через base_url, у Cursor есть выбор модели для cloud agents/automations и parallel agents, а у Warp/Oz модель можно задавать на уровне агента или workflow.

Но есть важная развилка. Нативно и красиво “локальные модели” лучше всего сейчас вписываются через Codex, потому что его конфиг прямо поддерживает model_provider, model_providers.<id>.base_url, заголовки, ключи и даже режим без auth, что в docs отдельно помечено как полезное для local models. Для Claude Code и Cursor публичные docs больше ориентированы на облачные провайдеры, allowlist моделей и gateway/managed deployments, а не на произвольный локальный OpenAI-compatible endpoint. У Warp есть multi-model, BYOK и enterprise BYOLLM через AWS Bedrock, но не нашёл в официальных docs такого же прямого “подключи localhost-LLM как штатную модель Warp Agent” пути.
Практический ответ

Да, архитектурно это делается так:

    Cloud lane
    Claude Code + Cursor Cloud Agents + Warp Cloud/Oz
    Для архитектуры, критичных PR, сложных миграций, security review, multi-file refactor.

    Local lane
    Codex через кастомный provider на локальный OpenAI-compatible endpoint
    Для triage, рутины, черновой генерации тестов, docs, grep-like анализа, дешёвых rewrite-задач.

Что я бы считал правильной политикой приоритетов
P0: критично и рискованно

Сюда относятся:

    security-sensitive изменения

    архитектурные решения

    миграции схем/данных

    сложные баги с неясной причиной

    финальный review перед merge

Маршрут:

    Claude Code opus или opusplan

    затем финальная проверка в Cursor/человеком

    при необходимости Codex только как исполнитель под уже готовый план.
    Claude Code официально поддерживает opusplan, где plan mode идёт на Opus, а execution mode автоматически переключается на Sonnet. Это почти готовая “встроенная маршрутизация по сложности” внутри одного инструмента.

P1: важные, но не ядерные задачи

Сюда:

    обычные feature-задачи

    refactor в известных границах

    интеграция нового модуля

    написание и починка тестов

Маршрут:

    Codex cloud profile или Claude Sonnet

    если контекст большой, можно держать Claude для планирования, а Codex для реализации.
    Codex позволяет задавать модель и reasoning effort в конфиге и менять их через /model, а также держать отдельный review_model.

P2: дешёвая рутина

Сюда:

    преобразование кода по шаблону

    генерация boilerplate

    маленькие тесты

    документация

    извлечение структуры из файлов

    предварительная классификация issue

Маршрут:

    local model через Codex custom provider

    при низкой уверенности эскалация в облако.

P3: фоновая механика

Сюда:

    суммаризация логов

    сортировка задач

    построение candidate-list файлов

    простые code comments

    начальная черновая декомпозиция

Маршрут:

    local model почти по умолчанию

    если задача не уложилась в confidence threshold, автоматический retry в cloud lane

Важный нюанс про AirLLM

AirLLM можно использовать, но не как самый удобный “прямой backend” для этого стека.
По официальному репозиторию AirLLM это библиотека для memory-efficient inference: она умеет запускать большие модели на малой VRAM, загружать модель из Hugging Face или локального пути, и у неё есть режимы ускорения через compression. Но это именно библиотека/рантайм, а не стандартный агентный endpoint “из коробки”.

Поэтому для интеграции с агентами я бы рекомендовал такое правило:

    AirLLM можно использовать как технологию локального inference

    но наружу лучше отдавать OpenAI-compatible API endpoint

    для этого обычно удобнее vLLM, Ollama или LM Studio, потому что под них есть готовые схемы запуска локальных моделей и локального API; OpenAI отдельно показывает локальный запуск gpt-oss через Ollama, LM Studio и vLLM, а vLLM поднимает сервер на localhost:8000.

То есть мой честный инженерный вывод такой:

AirLLM хорош как движок локального inference, но как слой интеграции для Codex/оркестрации я бы чаще выбрал vLLM/Ollama/LM Studio.
Что реально можно настроить по инструментам
Claude Code

У Claude Code есть уже почти готовая логика “умный гибрид”:

    haiku для простого

    sonnet для повседневной кодовой работы

    opus для сложного reasoning

    opusplan для split: план на Opus, исполнение на Sonnet

    отдельный effort: low, medium, high, max

    отдельная модель для subagents через CLAUDE_CODE_SUBAGENT_MODEL

    custom model option для gateway deployments.

Вывод: Claude Code прекрасно годится для cloud lane, особенно для приоритета и staged execution.
Codex

Codex здесь самый гибкий:

    можно задавать default model

    reasoning effort

    profiles

    custom model providers с base_url

    provider без auth, что docs отдельно связывают с local models

    /model для переключения в сессии

    отдельный review_model.

Вывод: именно Codex я бы сделал мостом в local lane.
Cursor

Cursor умеет:

    Auto, где сам балансирует intelligence/cost/reliability

    явный выбор модели

    cloud agents/automations с выбором модели

    parallel agents, включая запуск prompt across multiple models

    hooks для расширения agent loop.

Но по публичным docs я не вижу надёжного подтверждения, что Cursor нативно принимает произвольный локальный OpenAI-compatible endpoint как обычную модель. Docs говорят про свои модели и API keys для supported providers. Поэтому Cursor лучше использовать как кабину пилота и policy-entrypoint, а не как главный local-model runtime.
Warp / Oz

Warp/Oz удобен как orchestration-layer:

    multi-model by design

    model choice configurable per agent/workflow

    cloud agents часто смешивают дешёвые и сильные модели по типу задачи

    BYOK для выбранных моделей

    enterprise BYOLLM через AWS Bedrock

    отлично живёт рядом с Codex CLI и Claude Code CLI.

Но для истинно локального маршрута на ноутбук я бы делал так: Warp запускает Codex local profile, а не пытается сам стать universal host for AirLLM.
Как бы я построил policy-router

Вот хороший каркас.

routing:
  p0_critical:
    match:
      - security
      - migration
      - architecture
      - unclear_root_cause
      - cross_repo_change
    run:
      planner: claude:opusplan
      executor: codex:cloud-high
      reviewer: claude:opus
      fallback: human-review-required

  p1_standard:
    match:
      - feature
      - refactor
      - integration
      - medium_test_work
    run:
      planner: claude:sonnet
      executor: codex:cloud-medium
      reviewer: cursor:auto

  p2_routine:
    match:
      - boilerplate
      - docs
      - rename
      - simple_tests
      - log_summarization
    run:
      planner: codex:local-fast
      executor: codex:local-fast
      escalation_on:
        - low_confidence
        - tool_error
        - large_diff
      escalate_to: codex:cloud-medium

  p3_background:
    match:
      - issue-triage
      - file-candidate-search
      - changelog-draft
    run:
      executor: codex:local-cheap
      escalate_to: claude:haiku

Это не встроенная фича одного продукта. Это policy поверх продуктов.
Самый рабочий вариант у тебя

Если делать это без лишней экзотики, я бы рекомендовал такую архитектуру:

    Cursor
    как UI, rules, hooks, ручной override, наблюдение за pipeline.

    Claude Code
    только cloud lane, для сложного и важного. Использовать opusplan, opus, sonnet, effort и subagent model.

    Codex
    два профиля:

        cloud-medium

        local-fast
        Локальный профиль смотрит в http://localhost:8000/v1 или другой OpenAI-compatible endpoint. Это прямо соответствует модели custom provider в Codex config.

    Локальный сервер модели
    Лучше vLLM / Ollama / LM Studio. AirLLM можно держать как исследовательский движок, но для production-like роутинга удобнее API-first слой.

    Warp/Oz
    как runner для pipeline и headless execution. В нём уже удобно разводить workflow по агентам и моделям.

Ограничения, о которых лучше знать заранее

    Да, приоритизацию по сложности и цене сделать можно.

    Нет, не у всех четырёх одинаково хорошо получается ходить в локальные модели.

    На сегодня самый чистый local lane у тебя получится через Codex + local OpenAI-compatible serving.

    Claude Code лучше оставить облачным мозгом.

    Cursor лучше оставить управляющим интерфейсом.

    Warp/Oz лучше использовать как диспетчер, а не как место, где ты насильно встраиваешь каждый тип модели одинаковым способом.

Если хочешь, следующим сообщением я соберу тебе конкретную схему роутинга с файлами конфигурации: config.toml для Codex, policy YAML, приоритетную матрицу задач и пример запуска local/cloud lane.

Давай подробный гайд инструкцию как это все оплатить, как с этим работать а главное нужны удобные инструменты для создания и редактирования блюпринтов, правил и док 

Сейчас соберу это как карту снабжения и эксплуатации: кто как оплачивается, что брать на старте, где скрыты лимиты, и какими редакторами удобно вести сами blueprint-ы, правила и системные доки. Затем сведу это в практичный набор “что купить первым, что подключить позже”.

Да. Собирать это лучше не как “купить всё подряд”, а как трёхслойный набор:

    редактор и агентный UI,

    облачные coding-агенты,

    место, где живут твои blueprint-ы, rules и docs. У Cursor Pro сейчас есть MCP, skills, hooks и cloud agents; Claude Pro включает Claude Code; Codex доступен в ChatGPT-планах, а Warp можно взять на free или Build с кредитами и BYOK.

Что покупать и в каком порядке

Для одного человека я бы брал так:

    Cursor Pro за $20/мес. Это самый полезный первый платёж, потому что он даёт расширенные agent limits, frontier models, MCP, skills, hooks и cloud agents.

    ChatGPT Plus за $20/мес. Plus даёт расширенный доступ в ChatGPT, а Codex включён в платные ChatGPT-планы; для GPT-5.3-Codex OpenAI отдельно пишет, что он доступен в Codex app, CLI, IDE extension и web с paid ChatGPT plans.

    Claude Pro за $20/мес или эквивалент $17/мес при годовой оплате. В Pro включён Claude Code.

    Warp сначала можно оставить на Free, а если зайдёт orchestration и облачные агенты, перейти на Build, который стартует примерно от $20/мес, включает 1,500 AI credits и BYOK. У Warp также есть free-уровень с ограниченными AI credits, model access, cloud agents access и codebase indexing.

То есть твой нормальный стартовый бюджет будет таким:
$60/мес без платного Warp, или около $80/мес с Warp Build. Это уже рабочая связка, а не подписочный зоопарк.

Если ты реально будешь жить в этом по 8-10 часов в день, тогда уже есть power-user варианты: Cursor Pro+ $60, Cursor Ultra $200, Claude Max от $100, ChatGPT Pro $200. Но это уже тяжёлый режим и покупать его с порога я бы не советовал.
Как именно это оплачивать

У OpenAI всё просто: входишь в ChatGPT, жмёшь Profile → Upgrade plan, выбираешь Get Plus или Get Pro. OpenAI пишет, что Go, Plus, Pro и Business можно покупать любой major credit card. API в эти подписки не входит и биллится отдельно.

У Cursor, Claude и Warp логика обычная: заходишь на pricing page, авторизуешься и оформляешь подписку на свой аккаунт. По текущим pricing pages у Cursor есть Hobby/Pro/Pro+/Ultra и Teams, у Claude есть Pro и Max, у Warp есть Free и Build, плюс Business-уровень.

Если позже захочешь строить свои автоматизации через API, это отдельный кошелёк. У OpenAI на API-странице сейчас для gpt-5.3-codex указаны $1.75 input / $0.175 cached input / $14 output за 1M tokens в standard, а tools вроде web search, file search и containers тарифицируются отдельно. У Anthropic API-цены для Claude Sonnet 4.6 сейчас $3 input / $15 output за 1M tokens, а для Claude Opus 4.6 $5 input / $25 output.
Как с этим работать каждый день

Самый удобный режим такой:

1. Придумываешь и раскладываешь идею в Obsidian.
Obsidian хорошо подходит именно как мозговая мастерская: у него есть links для связей между заметками, а Canvas даёт бесконечное визуальное полотно для схем, исследований и раскладки идей; Canvas хранится в открытом JSON Canvas формате, так что его можно долго жить и автоматизировать.

2. Каноническую версию blueprint-ов хранишь в Git-репозитории.
Не в Notion, не в чате, не в Warp Drive как единственном источнике. Почему: Codex читает AGENTS.md до начала работы, поддерживает проектные .codex/config.toml, а Claude Code начинает с CLAUDE.md и проектных .claude/settings.json. То есть именно repo-файлы для агентов являются “железными рельсами”.

3. Редактируешь rules, configs и markdown в Cursor.
Cursor здесь хорош как центральный cockpit: в Pro-плане есть hooks, skills, MCP и cloud agents, а plugins в Cursor умеют упаковывать rules, skills, agents, commands, MCP servers и hooks в переиспользуемые bundle-пакеты. Это почти готовая фабрика для твоих долгоживущих blueprint-ов.

4. Claude и Codex получают от тебя не “свободный текст”, а формализованный пакет.
То есть задача начинается не с “сделай фичу”, а с набора файлов: brief.md, plan.md, tasks.yaml, AGENTS.md, CLAUDE.md, .codex/config.toml, .claude/settings.json. У Codex есть ещё и skills, где workflow можно упаковать в папку с SKILL.md, скриптами и references; это очень хорошо подходит для повторяемых операций вроде feature, bugfix, review, migration.

5. Warp используй как диспетчерскую, а не как источник истины.
У Warp есть Workflows, Notebooks, Prompts, Rules, Drive, и его агенты используют эти объекты как контекст. Плюс у него есть встроенный file editor с LSP, можно редактировать планы прямо там. Но я бы держал в Warp только operational-слой: повторяемые команды, runbooks, временные orchestration-объекты. Истина всё равно должна жить в git.
Какие инструменты лучшие для blueprint-ов, правил и доков

Мой практичный набор здесь такой.

Лучшее место для чернового проектирования: Obsidian.
Особенно для тебя, потому что ты уже в нём живёшь. Canvas хорош именно для “раскладывания системы на столе”, а обычные markdown notes хороши для концептов, связей и карты знаний. Если захочешь быстро публиковать часть материалов наружу, у Obsidian Publish сейчас цена $8/мес при годовой оплате или $10/мес помесячно за сайт.

Лучшее место для канонических rules/config/docs: репозиторий + Cursor.
Причина очень простая: Codex официально использует AGENTS.md и проектный .codex/config.toml; Claude Code использует CLAUDE.md, .claude/settings.json и поддерживает user/project/local scope. Ещё приятная деталь: Anthropic прямо пишет, что добавление $schema в settings.json даёт autocomplete и inline validation в VS Code, Cursor и других редакторах с JSON schema validation. Это делает редактирование правил сильно менее мучительным.

Лучшее место для “читаемых” долгоживущих docs-порталов: Docusaurus.
У него есть нормальная versioning CLI, которая сохраняет конкретную версию docs даже когда основной docs каталог дальше меняется. Для системы с blueprint-v1 / v2 / v3 это почти идеальный профиль.

Лучшее место для wiki для команды и нетехнарей: Notion.
Notion удобен именно как team wiki: официальные гайды описывают его как красивый общий wiki/central repository с sub-pages, callouts, table of contents и embed-ами. Это хорошо для онбординга, governance и executive-level документации. Но я бы не делал Notion единственным source of truth для агентных правил.

Что с MkDocs Material:
Если нужен быстро поднимаемый docs-site с хорошим встроенным search и Mermaid, он всё ещё очень приятный. Но есть важный нюанс: команда объявила Material for MkDocs в maintenance mode с ноября 2025 года, без новых фич, и в changelog уже видны предупреждения про совместимость с MkDocs 2.0. Поэтому для нового многолетнего blueprint-портала я бы выбирал Docusaurus, а MkDocs держал бы как лёгкий вариант для стабильных внутренних docs.
Моя конкретная рекомендация тебе

Я бы собрал твой стек так:

    Obsidian для замысла, Canvas, карты системы и draft-архитектуры.

    Cursor Pro как главный редактор и место, где ты правишь markdown, YAML, TOML, JSON и запускаешь агентные задачи.

    ChatGPT Plus для Codex как рабочего инженерного исполнителя.

    Claude Pro для Claude Code как архитектора и review-мозга.

    Warp Free, а потом Build, когда реально понадобятся shared workflows, BYOK и orchestration credits.

    Docusaurus для долгоживущих публичных или внутренних версионируемых docs.

    Notion только как витрина/вики для команды, если нужно.

Если делать совсем короткий вердикт, то он такой:
покупай сначала Cursor Pro + ChatGPT Plus + Claude Pro, а Warp оставь бесплатным до тех пор, пока не почувствуешь реальную боль от orchestration и shared runbooks. Для blueprint-ов и правил держи истину в Git, редактируй её в Cursor, проектируй в Obsidian, а публикуй в Docusaurus. Это самая устойчивая схема на годы.

Следующим сообщением я могу дать тебе готовую структуру папок и шаблоны файлов для AGENTS.md, CLAUDE.md, .codex/config.toml, .claude/settings.json и blueprints/feature-v1.md.

Окей
Сделай полный цикл на любой абстрактной, но реальной задаче для наглядности 

Возьму реальную, но безопасно-абстрактную задачу из веб-бэкенда и прогоню её через весь конвейер: intake → blueprint → план → разрезание задач → исполнение через Claude/Codex → проверки → PR → ретро. Покажу не только шаги, но и сами файлы, команды и то, кто в какой момент за что отвечает.

Ниже будет полный прогон по реальной задаче, как будто у тебя уже есть стек:

    Cursor как главный редактор

    Claude Code как архитектор и reviewer

    Codex как исполнитель

    Warp как диспетчерская

    Git + worktrees как изоляция

    Blueprint-ы в репозитории как память системы

Возьмём задачу не игрушечную, а вполне боевую.
Сценарий
Проект

billing-service на Python + FastAPI + PostgreSQL.
Проблема

Платёжный провайдер шлёт webhook о подтверждении оплаты. Иногда он делает retry одного и того же события. Сейчас сервис обрабатывает webhook повторно, из-за чего:

    дублируются платежи в журнале

    повторно активируется подписка

    летят дублирующие письма

Что надо сделать

Добавить идемпотентную обработку webhook:

    хранить provider_event_id

    не обрабатывать одно и то же событие дважды

    логировать результат

    покрыть тестами

    подготовить PR и docs note

Это хорошая задача для демонстрации, потому что тут есть:

    архитектура

    миграция БД

    код

    тесты

    review

    приоритизация local/cloud

    финальный PR

0. Что уже лежит в репозитории

repo/
├─ .ai/
│  ├─ base/
│  │  ├─ BASE.md
│  │  ├─ architecture-map.md
│  │  └─ done-criteria.md
│  ├─ blueprints/
│  │  ├─ feature-v1.md
│  │  ├─ bugfix-v1.md
│  │  └─ critical-bugfix-v1.md
│  ├─ pipelines/
│  │  ├─ routing.yaml
│  │  └─ critical-change.yaml
│  └─ runs/
├─ .codex/
│  └─ config.toml
├─ .claude/
│  └─ settings.json
├─ .cursor/
│  └─ rules/
├─ AGENTS.md
├─ CLAUDE.md
├─ scripts/
│  ├─ plan-init.sh
│  ├─ blueprint-run.sh
│  ├─ ai-check.sh
│  └─ package-pr.sh
└─ app/

1. Классификация задачи

Эта задача попадает в P0 / критичная, потому что:

    деньги

    внешние вебхуки

    возможны повторы

    затрагивается бизнес-логика и БД

Значит роутинг такой:

    план: Claude Code, cloud, сильная модель

    реализация ядра: Codex, cloud

    мелкие вспомогательные вещи: local model через Codex profile

    финальный review: Claude Code

    ручная сборка и diff review: Cursor

2. Запуск нового run

В Warp ты открываешь проект и стартуешь новый run.

./scripts/plan-init.sh PAY-1842 critical-bugfix-v1

Скрипт создаёт:

.ai/runs/2026-03-21-PAY-1842/
├─ brief.md
├─ routing.yaml
├─ plan.md
├─ tasks.yaml
├─ findings.md
├─ verification.md
├─ pr-body.md
└─ retro.md

3. Intake: brief.md

Сначала не код. Сначала нормальная постановка.

.ai/runs/2026-03-21-PAY-1842/brief.md

# PAY-1842

## Title
Make payment webhook handling idempotent

## Problem
The payment provider retries webhook delivery on network errors.
The same event may be processed multiple times, causing duplicate side effects.

## Goal
Process each provider event at most once.

## Scope
- Add persistent storage for processed provider events
- Check idempotency before applying side effects
- Log duplicate detection
- Add unit/integration tests

## Out of scope
- Refactor unrelated payment flows
- Change provider signature validation logic
- Rebuild notification system

## Constraints
- Keep current API contract
- Preserve existing subscription activation path
- No breaking DB changes to existing tables

## Risks
- Concurrency race on duplicate delivery
- Transaction boundaries may allow partial side effects
- Historical events do not exist in new table

## Definition of done
- Duplicate webhook event does not produce duplicate subscription activation
- Duplicate webhook event returns safe success response
- Tests cover first delivery and repeated delivery
- Migration is reversible

Вот это и есть вход для агентов. Не “сделай нормально”, а маленький контракт.
4. Blueprint, который выбирается автоматически

.ai/blueprints/critical-bugfix-v1.md

# critical-bugfix-v1

Use this blueprint for money, auth, data integrity, or security-adjacent defects.

## Stages
1. brief validation
2. architecture plan
3. task slicing
4. isolated implementation
5. deterministic verification
6. architecture review
7. PR packaging
8. retro

## Mandatory outputs
- brief.md
- plan.md
- tasks.yaml
- verification.md
- findings.md
- pr-body.md
- retro.md

## Mandatory gates
- DB migration reviewed
- test suite passed
- duplicate/race path explicitly tested
- rollback note included

5. Claude делает план

В Warp или через wrapper ты запускаешь планирование.

./scripts/blueprint-run.sh plan PAY-1842

Под капотом скрипт делает примерно такую вещь:

    читает CLAUDE.md

    читает .ai/base/BASE.md

    читает brief.md

    запускает Claude на cloud-модели для planning stage

Что получает Claude

Пример системного входа:

Read:
- CLAUDE.md
- .ai/base/BASE.md
- .ai/base/architecture-map.md
- .ai/runs/2026-03-21-PAY-1842/brief.md

Task:
Produce a plan for an idempotent payment webhook fix.
Focus on transaction boundaries, duplicate event handling, schema design, and test strategy.
Do not implement code.
Write result to .ai/runs/2026-03-21-PAY-1842/plan.md

Что появляется в plan.md

# Plan

## Diagnosis
Current webhook flow applies side effects before any durable deduplication step.
This makes repeated provider deliveries unsafe.

## Proposed design
Introduce a new table `processed_webhook_events` with:
- provider_name
- provider_event_id
- received_at
- processed_at
- status
- payload_hash

Create a unique constraint on (provider_name, provider_event_id).

## Execution flow
1. Verify signature as before
2. Start DB transaction
3. Try to register event row
4. If unique conflict occurs:
   - mark request as duplicate
   - skip side effects
   - return safe success response
5. If registration succeeds:
   - apply payment side effects
   - mark event as processed
   - commit transaction

## Risks
- Side effects outside DB transaction must be delayed until commit or guarded
- Emails should not be sent before event registration succeeds
- Existing service methods may have hidden side effects

## Test strategy
- first delivery processes normally
- second identical delivery returns success without duplicate mutation
- concurrent duplicate attempts result in single effective processing
- migration rollback test

## Rollback
Drop new table and revert handler changes

Это уже пахнет архитектурой, а не автогеном.
6. План режется на задачи

Следующий stage: slicing.

.ai/runs/2026-03-21-PAY-1842/tasks.yaml

run_id: 2026-03-21-PAY-1842
blueprint: critical-bugfix-v1

tasks:
  - id: T1
    title: Add migration for processed webhook events
    priority: p0
    owner: codex-cloud
    outputs:
      - app/db/migrations/20260321_add_processed_webhook_events.py

  - id: T2
    title: Add repository methods for event registration and duplicate detection
    priority: p0
    owner: codex-cloud
    outputs:
      - app/payments/repository.py
      - tests/payments/test_repository_idempotency.py

  - id: T3
    title: Update webhook service transaction flow
    priority: p0
    owner: codex-cloud
    outputs:
      - app/payments/service.py
      - app/api/webhooks.py

  - id: T4
    title: Generate baseline unit tests for duplicate flow
    priority: p2
    owner: codex-local
    outputs:
      - tests/payments/test_webhook_duplicates.py

  - id: T5
    title: Review race conditions and side effects
    priority: p0
    owner: claude-cloud
    outputs:
      - .ai/runs/2026-03-21-PAY-1842/findings.md

  - id: T6
    title: Final integration review and PR packaging
    priority: p1
    owner: cursor-human
    outputs:
      - .ai/runs/2026-03-21-PAY-1842/verification.md
      - .ai/runs/2026-03-21-PAY-1842/pr-body.md

Вот здесь уже видно магию маршрутизации:

    тяжёлое и критичное идёт в cloud

    дешёвые тестовые заготовки можно отдать на local profile

7. Создаются worktrees

Чтобы агенты не дрались за один working tree:

git worktree add ../wt-pay-1842-codex -b pay-1842-codex
git worktree add ../wt-pay-1842-claude -b pay-1842-claude
git worktree add ../wt-pay-1842-review -b pay-1842-review

В Warp у тебя 3 панели:

    панель 1: wt-pay-1842-codex

    панель 2: wt-pay-1842-claude

    панель 3: основной проект, тесты и merge

8. Конфиг Codex с local/cloud профилями

.codex/config.toml

model = "gpt-5.3-codex"
model_reasoning_effort = "high"
approval_policy = "on-request"

[profiles.cloud_high]
model = "gpt-5.3-codex"
model_reasoning_effort = "high"

[profiles.cloud_medium]
model = "gpt-5.3-codex"
model_reasoning_effort = "medium"

[profiles.local_fast]
model = "qwen2.5-coder-32b"
model_provider = "local"
approval_policy = "never"

[model_providers.local]
name = "Local OpenAI-Compatible"
base_url = "http://127.0.0.1:8000/v1"
wire_api = "chat"
env_key = "DUMMY"

Смысл:

    cloud_high для T1-T3

    local_fast для T4

9. Базовые правила для Codex и Claude
AGENTS.md

Read .ai/base/BASE.md first.
For runs, use artifacts from .ai/runs/<run-id>/.
Never implement beyond current task scope.
Run scripts/ai-check.sh before marking task complete.
For DB changes:
- preserve backward compatibility
- include rollback note
- add tests for duplicate and race scenarios

CLAUDE.md

Read .ai/base/BASE.md first.
For critical tasks, plan before code.
Prefer explicit notes on risks, side effects, and rollback.
Review transaction boundaries carefully.
When reviewing code, focus on architecture drift and hidden side effects.

10. Исполнение T1-T3 через Codex cloud

Теперь Codex получает узкую задачу, а не всё сразу.
T1 prompt

Read:
- AGENTS.md
- .ai/base/BASE.md
- .ai/runs/2026-03-21-PAY-1842/brief.md
- .ai/runs/2026-03-21-PAY-1842/plan.md

Implement task T1 only:
Add a reversible migration for processed webhook events with a unique constraint on provider_name + provider_event_id.

Do not change service logic yet.
Update only files required for T1.

Codex в worktree делает миграцию.
Пример результата

def upgrade():
    op.create_table(
        "processed_webhook_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("provider_name", sa.String(length=50), nullable=False),
        sa.Column("provider_event_id", sa.String(length=255), nullable=False),
        sa.Column("payload_hash", sa.String(length=64), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="received"),
        sa.Column("received_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("processed_at", sa.DateTime(), nullable=True),
        sa.UniqueConstraint("provider_name", "provider_event_id", name="uq_provider_event"),
    )

def downgrade():
    op.drop_table("processed_webhook_events")

T2 prompt

Implement task T2 only.

Add repository methods:
- register_incoming_event(...)
- mark_event_processed(...)
- is_duplicate_event(...)

Use DB uniqueness as the source of truth.
Add repository tests.
Do not update API handlers yet.

Пример результата

class WebhookEventRepository:
    def register_incoming_event(self, session, provider_name: str, provider_event_id: str, payload_hash: str | None):
        event = ProcessedWebhookEvent(
            provider_name=provider_name,
            provider_event_id=provider_event_id,
            payload_hash=payload_hash,
            status="received",
        )
        session.add(event)
        try:
            session.flush()
            return event, False
        except IntegrityError:
            session.rollback()
            return None, True

    def mark_event_processed(self, session, event_id: int) -> None:
        session.execute(
            update(ProcessedWebhookEvent)
            .where(ProcessedWebhookEvent.id == event_id)
            .values(status="processed", processed_at=datetime.utcnow())
        )

T3 prompt

Implement task T3 only.

Update webhook processing flow:
- keep signature validation unchanged
- start transaction
- register incoming event
- if duplicate: return safe success response and skip side effects
- if first delivery: apply payment effects and mark processed

Do not send notifications before deduplication is confirmed.

Пример результирующей логики

def handle_payment_webhook(payload: dict, signature: str) -> dict:
    verify_signature(payload, signature)

    provider_event_id = payload["event_id"]

    with session_scope() as session:
        event, is_duplicate = webhook_repo.register_incoming_event(
            session=session,
            provider_name="acmepay",
            provider_event_id=provider_event_id,
            payload_hash=hash_payload(payload),
        )

        if is_duplicate:
            logger.info("Duplicate webhook ignored", extra={"event_id": provider_event_id})
            return {"status": "ok", "duplicate": True}

        payment_service.apply_successful_payment(session, payload)
        webhook_repo.mark_event_processed(session, event.id)

    return {"status": "ok", "duplicate": False}

11. T4 через local model

Теперь экономим лимиты.

T4 не несёт архитектурного риска. Это генерация тестовой болванки. Её можно отдать локальной модели.

codex --profile local_fast

Prompt:

Implement task T4 only.

Generate baseline unit tests for duplicate webhook processing:
- first delivery applies changes
- second delivery is ignored
- response stays successful
Keep tests minimal and readable.

Что получится

def test_duplicate_webhook_is_ignored(client, seeded_subscription, mock_provider_payload):
    first = client.post("/webhooks/payment", json=mock_provider_payload)
    second = client.post("/webhooks/payment", json=mock_provider_payload)

    assert first.status_code == 200
    assert second.status_code == 200
    assert second.json()["duplicate"] is True

    subscription = get_subscription(seeded_subscription.id)
    assert subscription.status == "active"
    assert count_payment_events(mock_provider_payload["event_id"]) == 1

Это отличный кандидат на local lane:

    недорого

    быстро

    не жалко, если потом придётся подправить

12. Claude делает review ядра

Теперь включается архитектор.

Prompt для Claude:

Read:
- CLAUDE.md
- .ai/base/BASE.md
- .ai/runs/2026-03-21-PAY-1842/brief.md
- .ai/runs/2026-03-21-PAY-1842/plan.md
- current diff in payment-related files

Review the implementation for:
- transaction safety
- duplicate race handling
- hidden side effects before durable deduplication
- architecture drift

Write findings to .ai/runs/2026-03-21-PAY-1842/findings.md
Do not rewrite code unless a critical flaw exists.

findings.md

# Findings

## Good
- DB uniqueness is used as the true deduplication gate
- Duplicate path returns safe success
- Side effects are now after event registration

## Risks
- register_incoming_event currently rolls back session on IntegrityError.
  This may discard unrelated state if the session is reused elsewhere.

## Recommendation
Use a nested transaction or isolate event registration flush inside a smaller transaction boundary.

## Minor follow-up
Add an integration test simulating two concurrent deliveries.

Вот это и есть польза Claude: не “написал ещё 200 строк”, а поймал тонкую трещину в шве.
13. Cursor как финальный cockpit

Теперь ты открываешь всё в Cursor и смотришь:

    diff по миграции

    diff по service.py

    findings Claude

    тесты

    где rollback слишком грубый

    нет ли лишних изменений

В Cursor ты руками или через встроенный agent докручиваешь кусок с rollback.

Например меняешь T2 так, чтобы IntegrityError обрабатывался через nested transaction, а не обнулял всё подряд.
14. Проверка

Единый скрипт:

scripts/ai-check.sh

#!/usr/bin/env bash
set -euo pipefail

ruff check app tests
black --check app tests
mypy app
pytest -q

Запуск:

./scripts/ai-check.sh

Результат пишется в verification.md.

# Verification

## Static checks
- ruff: passed
- black --check: passed
- mypy: passed

## Tests
- unit tests: passed
- webhook duplicate tests: passed
- repository tests: passed

## Manual checks
- repeated webhook returns 200
- duplicate path does not create second subscription mutation
- migration downgrade executed successfully in local environment

15. PR packaging

Теперь упаковка.

./scripts/package-pr.sh PAY-1842

pr-body.md

# PAY-1842: make payment webhook handling idempotent

## Why
Provider retries may deliver the same webhook multiple times.
Previously this could duplicate business side effects.

## What changed
- added `processed_webhook_events` table
- added unique constraint for provider event identity
- registered incoming events before applying payment side effects
- ignored duplicate deliveries safely
- added tests for duplicate flow

## Risks
- touches payment processing path
- introduces new persistence layer for webhook events

## Rollback
- revert handler changes
- drop `processed_webhook_events` table

## Verification
- lint/type/tests passed
- duplicate webhook path tested

16. Что коммитится

Пример нормальных коммитов:

git add app/db/migrations/20260321_add_processed_webhook_events.py
git commit -m "feat(payments): add webhook event idempotency table"

git add app/payments/repository.py app/payments/service.py app/api/webhooks.py
git commit -m "fix(payments): ignore duplicate webhook deliveries"

git add tests/payments/
git commit -m "test(payments): cover duplicate webhook flow"

git add .ai/runs/2026-03-21-PAY-1842/
git commit -m "docs(ai): store run artifacts for PAY-1842"

17. Ретро

После merge делается самое ценное: система учится.

.ai/runs/2026-03-21-PAY-1842/retro.md

# Retro

## What worked
- Planning first prevented a naive in-memory deduplication solution
- Task slicing reduced scope creep
- Local model was good enough for baseline tests
- Claude review caught an over-broad rollback issue

## What to improve
- critical DB tasks should always include nested transaction guidance
- critical-bugfix blueprint should explicitly ask for concurrent duplicate test

## Blueprint updates
- update critical-bugfix-v1 -> v2
- add checklist item: "avoid session-wide rollback on uniqueness race"

И вот это уже не просто “мы сделали задачу”.
Это “мы сделали задачу и улучшили фабрику”.
18. Как это выглядит в живом рабочем дне

Чтобы картина не была картонной, вот как это выглядит по ролям.
В Obsidian

Ты черново раскладываешь проблему:

    где сейчас вход webhook

    какие side effects

    где риск дубля

Это исследовательская стадия.
В Git

Канон живёт в:

    BASE.md

    AGENTS.md

    CLAUDE.md

    blueprint-ах

    scripts

В Warp

Ты:

    запускаешь новый run

    открываешь 3 панели

    смотришь тесты

    гоняешь Codex и Claude

В Claude

Ты получаешь:

    план

    риск-анализ

    review

В Codex

Ты получаешь:

    миграцию

    репозиторий

    сервисные изменения

    черновые тесты

В Cursor

Ты:

    сводишь diff

    принимаешь решения

    делаешь финальную сборку PR

19. Почему этот цикл хороший

Потому что он не строится на магии. Он строится на простых штуках:

    у задачи есть brief

    у плана есть отдельный stage

    код не пишется в одном общем болоте

    critical и routine таски идут в разные model lanes

    есть единый скрипт проверки

    есть артефакты run-а

    есть retro

    blueprint улучшается после каждой живой задачи

Это уже настоящий pipeline, а не “чатик попросили пописать код”.
20. Мини-версия того же цикла одной командой

Когда система созреет, ты можешь запускать это так:

just run PAY-1842

А внутри будет:

    создать run directory

    выбрать blueprint

    прогнать Claude planning

    сгенерировать tasks.yaml

    развести задачи по cloud/local

    создать worktrees

    запустить Codex для implementation

    запустить local model для cheap subtasks

    прогнать ai-check.sh

    прогнать Claude review

    собрать pr-body.md

    записать retro.md

Вот это уже и есть маленький кодовый конвейер, который можно полировать годами.

Следом могу сделать то же самое, но в виде готового starter-kit файлов для Python-репозитория: с шаблонами AGENTS.md, CLAUDE.md, config.toml, routing.yaml, critical-bugfix-v1.md и justfile.

Ты скрипты и команды запускал
Это что за скрипты и команды? Они реально существующие рабочие или ты их выдумал? 

Проверю по-честному, где у меня были реальные команды экосистемы, а где я показал каркас, который нужно создать самому. Лучше это разделить, чтобы не было бумажного моторчика вместо рабочего.

Честно: часть была реальной, часть была намеренно выдуманным каркасом для демонстрации полного цикла.

Разделю без тумана.

Реальные существующие команды/механики:

    git worktree add ... это настоящая команда Git для нескольких working tree.

    codex --profile <name> это реальный режим Codex CLI; профили задаются в config.toml, и OpenAI прямо показывает запуск через codex --profile <name>. Профили при этом помечены как experimental.

    .codex/config.toml это реальный конфиг Codex, причём он может быть project-scoped в .codex/config.toml.

    .claude/settings.json это реальный механизм настроек Claude Code, с project-level файлом .claude/settings.json. Hooks у Claude Code тоже реальны.

    just это реальный command runner, но только если он у тебя установлен и если в репо есть justfile.

Выдуманные мной как пример и не существующие “из коробки”:

    ./scripts/plan-init.sh

    ./scripts/blueprint-run.sh

    ./scripts/ai-check.sh

    ./scripts/package-pr.sh

    структура .ai/runs/...

    just run PAY-1842 как конкретная recipe

    сами blueprint-файлы и routing YAML в том виде, как я показал

Это были не штатные команды Cursor / Claude / Codex / Warp, а скрипты, которые ты сам создаёшь в своём репозитории, чтобы сделать из набора инструментов нормальный pipeline.

То есть логика была такая:

    я взял реальные кирпичи: Git worktree, Codex profiles, Claude settings/hooks, just

    и поверх них нарисовал твою будущую обвязку, которую надо написать самому

Ещё один важный нюанс: команды вроде

ruff check app tests
black --check app tests
mypy app
pytest -q

тоже реальные команды реальных инструментов, но в моём примере они были иллюстративными. Они сработают только если у тебя эти инструменты установлены и проект действительно использует именно их. Это не “универсальный стандарт”, а типичный Python quality gate.

Итого в одной фразе:

ядро было реальным, а конвейерная обвязка была концептуально правдоподобной, но не готовой встроенной системой.

Чтобы было совсем прозрачно, вот классификация:

    реально существует у вендоров/инструментов: git worktree, codex --profile, .codex/config.toml, .claude/settings.json, Claude hooks, just

    реально существует как общие dev-tools, но не гарантировано у тебя: pytest, ruff, black, mypy

    я придумал как шаблон для твоего репо: все scripts/*.sh, just run PAY-1842, .ai/runs/..., blueprint routing

Самое полезное продолжение здесь такое: я могу теперь сделать две версии следующего шага. Либо “честный макет”, где всё остаётся псевдо-командами, либо “реально запускаемый starter kit” с настоящими файлами и командами, которые ты сможешь положить в репозиторий и сразу гонять.

Доведи до ума идею
Скрипты, команды 

Сейчас переведу всё из “архитектурной легенды” в рабочий каркас: только реальные команды, реальные точки интеграции и те скрипты, которые ты сможешь создать у себя без фантомных зависимостей. Сразу отделю обязательное от опционального, чтобы не построить космодром ради одного webhook-а.

Уже есть рабочий каркас: можно опереться на codex exec для скриптов/CI, на claude -p для неинтерактивных шагов, на project-level .codex/config.toml и .claude/settings.json, а orchestration держать в обычных shell-скриптах и justfile. Теперь соберу это в минимальную, но реальную систему без декоративных фантомов.

Да. Доведём до реально запускаемого каркаса, а не до бумажного дирижабля.

Ниже будет минимальный рабочий starter kit, который опирается только на реальные кирпичи:

    Codex умеет неинтерактивный запуск через codex exec, читает AGENTS.md до начала работы, поддерживает project-level .codex/config.toml, а профили реально существуют, хотя помечены как experimental и пока не работают в IDE extension.

    Claude Code умеет неинтерактивный режим через claude -p, project settings в .claude/settings.json, hooks в этом settings-файле и отдельный --worktree для изоляции.

    Warp/Oz можно подключить позже как headless runner для scripts/CI через oz agent run или oz agent run-cloud, но для первого рабочего контура он не обязателен.

    Cursor поддерживает project rules в .md/.mdc, а hooks умеют запускать пользовательские скрипты, так что редактор можно использовать как удобную кабину над этим же репозиторием.

    Для orchestration я возьму just как тонкий command runner. Это отдельный инструмент, не часть AI-стека, но он именно для хранения и запуска project-specific команд.

Сразу честно: все scripts/*.sh ниже ты создаёшь сам у себя в репо. Это не встроенные команды Claude/Codex/Warp. Зато они будут реально рабочими, если у тебя установлены git, bash, jq, claude, codex и, опционально, just.
Что получится в итоге

Ты сможешь делать вот такой цикл:

just run "PAY-1842 duplicate webhook handling"
# редактируешь .ai/runs/<run-id>/brief.md вручную

just plan <run-id>
just wt <run-id> codex
just wt <run-id> claude

cd ../wt-<run-id>-codex
just task <run-id> T1 cloud_high
just task <run-id> T2 local_fast
just checks

cd ../your-main-repo
just review <run-id>
just pr <run-id>

1. Структура репозитория

repo/
├─ .ai/
│  ├─ project.env.example
│  ├─ runs/
│  └─ logs/
├─ .codex/
│  └─ config.toml
├─ .claude/
│  └─ settings.json
├─ .cursor/
│  └─ rules/
│     └─ blueprints.mdc
├─ scripts/
│  ├─ new-run.sh
│  ├─ worktree.sh
│  ├─ plan.sh
│  ├─ task.sh
│  ├─ review.sh
│  ├─ pr-body.sh
│  └─ check.sh
├─ AGENTS.md
├─ CLAUDE.md
└─ justfile

2. Базовые инструкции для агентов
AGENTS.md

# AGENTS.md

## Working mode
- Read `.ai/runs/<run-id>/brief.md` and `.ai/runs/<run-id>/plan.md` before changing code.
- Stay inside the current task scope.
- Do not edit secrets, `.env*`, or deployment credentials.
- Run project checks before claiming completion.

## Change discipline
- Prefer minimal diffs.
- If database schema changes, include rollback notes.
- If behavior changes, add or update tests.
- Print a short summary of changed files and checks run at the end.

Codex читает AGENTS.md до начала работы, а ближние к текущей директории agent-files переопределяют более общие инструкции.
CLAUDE.md

# CLAUDE.md

## Role
You are the planner and reviewer.

## Planning rules
- Produce explicit diagnosis, risks, plan, rollback, and test strategy.
- Prefer small, verifiable tasks.
- Call out transaction boundaries, side effects, and race conditions.

## Review rules
- Focus on correctness, architecture drift, hidden side effects, and missing tests.
- Be conservative: recommend follow-up tasks instead of broad rewrites.

Claude Code project memory можно хранить в CLAUDE.md/.claude/CLAUDE.md, а project-level settings и hooks живут в .claude/settings.json.
3. Конфиг Codex
.codex/config.toml

model = "gpt-5-codex"
approval_policy = "on-request"

[profiles.cloud_high]
model = "gpt-5-codex"
model_reasoning_effort = "high"
approval_policy = "on-request"

[profiles.cloud_medium]
model = "gpt-5-codex"
model_reasoning_effort = "medium"
approval_policy = "on-request"

[profiles.local_fast]
model = "qwen2.5-coder:32b"
model_provider = "ollama"
approval_policy = "never"

[model_providers.ollama]
name = "Ollama"
base_url = "http://127.0.0.1:11434/v1"

Это реальный формат: у Codex есть project-level .codex/config.toml, профили под [profiles.<name>], CLI-переключение через codex --profile <name>, и custom providers с base_url, включая локальные OpenAI-compatible endpoints вроде Ollama. Профили официально experimental и пока не поддерживаются IDE extension, так что именно just/терминал здесь важнее редактора.
4. Конфиг Claude Code
.claude/settings.json

{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(pytest *)",
      "Bash(ruff check *)",
      "Bash(ruff format --check *)",
      "Bash(mypy *)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Bash(curl *)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p .ai/logs && jq -r '.tool_input.command' >> .ai/logs/claude-bash.log"
          }
        ]
      }
    ]
  }
}

Это тоже реальный механизм: settings.json является официальным способом конфигурации Claude Code, поддерживает project scope, permissions, hooks и JSON schema для autocomplete/validation в редакторах вроде Cursor и VS Code. Пример с PostToolUse и jq опирается на официальный hook pattern для Bash tool calls.
5. Настройки проекта для проверок
.ai/project.env.example

LINT_CMD="ruff check ."
FORMAT_CHECK_CMD="ruff format --check ."
TYPECHECK_CMD="mypy ."
TEST_CMD="pytest -q"

Скопируй в .ai/project.env и поправь под свой стек. Для Node/Go/Rust просто меняешь команды, а скрипт ниже не трогаешь.
6. Скрипты
scripts/check.sh

#!/usr/bin/env bash
set -euo pipefail

if [[ -f .ai/project.env ]]; then
  # shellcheck disable=SC1091
  source .ai/project.env
fi

run_if_set() {
  local label="$1"
  local cmd="${2:-}"
  if [[ -n "${cmd// }" ]]; then
    echo "==> ${label}"
    bash -lc "$cmd"
  fi
}

run_if_set "lint" "${LINT_CMD:-}"
run_if_set "format-check" "${FORMAT_CHECK_CMD:-}"
run_if_set "typecheck" "${TYPECHECK_CMD:-}"
run_if_set "tests" "${TEST_CMD:-}"

echo "All configured checks passed."

scripts/new-run.sh

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"issue or title\"" >&2
  exit 1
fi

title="$*"
slug="$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"

date_part="$(date +%F)"
run_id="${date_part}-${slug}"
run_dir=".ai/runs/${run_id}"

mkdir -p "${run_dir}"

cat > "${run_dir}/brief.md" <<EOF
# ${run_id}

## Title
${title}

## Problem
Describe the bug or feature in 3-8 lines.

## Goal
What should be true after this work?

## Scope
- 

## Out of scope
- 

## Constraints
- 

## Risks
- 

## Definition of done
- 
EOF

: > "${run_dir}/plan.md"
: > "${run_dir}/tasks.md"
: > "${run_dir}/review.md"
: > "${run_dir}/pr-body.md"

printf '%s\n' "${run_id}"

scripts/worktree.sh

#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 <run-id> <agent>}"
agent="${2:?Usage: $0 <run-id> <agent>}"

branch="${run_id}-${agent}"
path="../wt-${branch}"

if [[ -d "${path}" ]]; then
  printf '%s\n' "${path}"
  exit 0
fi

if git rev-parse --verify "${branch}" >/dev/null 2>&1; then
  git worktree add "${path}" "${branch}"
else
  git worktree add "${path}" -b "${branch}"
fi

printf '%s\n' "${path}"

git worktree add здесь настоящий Git-механизм, а Claude Code ещё и умеет собственный --worktree, если захочешь позже заменить этим часть обвязки.
scripts/plan.sh

#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 <run-id>}"
run_dir=".ai/runs/${run_id}"

[[ -f "${run_dir}/brief.md" ]] || { echo "Missing ${run_dir}/brief.md" >&2; exit 1; }

tmp_context="$(mktemp)"
trap 'rm -f "$tmp_context"' EXIT

{
  echo "=== BRIEF ==="
  cat "${run_dir}/brief.md"
  echo
  if [[ -f AGENTS.md ]]; then
    echo "=== AGENTS ==="
    cat AGENTS.md
    echo
  fi
  if [[ -f CLAUDE.md ]]; then
    echo "=== CLAUDE ==="
    cat CLAUDE.md
    echo
  fi
} > "$tmp_context"

cat "$tmp_context" | claude -p \
  --model opus \
  --max-turns 8 \
  --append-system-prompt-file CLAUDE.md \
  "Create a technical plan from the supplied brief.

Return markdown only with these headings exactly:
# Plan
## Diagnosis
## Risks
## Proposed approach
## Rollback
## Test strategy" > "${run_dir}/plan.md"

cat "$tmp_context" "${run_dir}/plan.md" | claude -p \
  --model sonnet \
  --max-turns 6 \
  --append-system-prompt-file CLAUDE.md \
  "Slice the work into small implementation tasks.

Return markdown only.
Use headings exactly like:
## T1: <title>
Goal:
Files:
Acceptance criteria:

Create 3 to 7 tasks." > "${run_dir}/tasks.md"

echo "Wrote ${run_dir}/plan.md and ${run_dir}/tasks.md"

claude -p это официальный неинтерактивный режим, а --append-system-prompt-file и --model тоже реальные флаги CLI.
scripts/task.sh

#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 <run-id> <task-id> [profile] }"
task_id="${2:?Usage: $0 <run-id> <task-id> [profile] }"
profile="${3:-cloud_high}"

run_dir=".ai/runs/${run_id}"
tasks_file="${run_dir}/tasks.md"
plan_file="${run_dir}/plan.md"
brief_file="${run_dir}/brief.md"

[[ -f "$tasks_file" ]] || { echo "Missing ${tasks_file}" >&2; exit 1; }
[[ -f "$plan_file" ]] || { echo "Missing ${plan_file}" >&2; exit 1; }
[[ -f "$brief_file" ]] || { echo "Missing ${brief_file}" >&2; exit 1; }

task_body="$(
  awk -v task="## ${task_id}:" '
    $0 ~ "^## T[0-9]+:" {
      if (capture) exit
    }
    index($0, task) == 1 { capture=1 }
    capture { print }
  ' "$tasks_file"
)"

[[ -n "${task_body// }" ]] || { echo "Task ${task_id} not found in ${tasks_file}" >&2; exit 1; }

tmp_prompt="$(mktemp)"
trap 'rm -f "$tmp_prompt"' EXIT

{
  echo "Implement exactly one task in the current repository."
  echo
  echo "When finished, print:"
  echo "1. changed files"
  echo "2. short summary"
  echo "3. checks you ran"
  echo
  echo "=== TASK ==="
  printf '%s\n' "$task_body"
  echo
  echo "=== BRIEF ==="
  cat "$brief_file"
  echo
  echo "=== PLAN ==="
  cat "$plan_file"
} > "$tmp_prompt"

mkdir -p "${run_dir}/logs"

codex --profile "${profile}" exec --full-auto "$(cat "$tmp_prompt")" \
  | tee "${run_dir}/logs/${task_id}.md"

Здесь используется ровно то, что у Codex реально есть: codex exec для scripts/CI, --full-auto для режима с правками, и --profile для выбора набора конфигурации. По умолчанию codex exec идёт в read-only sandbox, так что для реального исполнения правок нужен --full-auto или более широкий sandbox.
scripts/review.sh

#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 <run-id>}"
run_dir=".ai/runs/${run_id}"

[[ -f "${run_dir}/brief.md" ]] || { echo "Missing brief.md" >&2; exit 1; }
[[ -f "${run_dir}/plan.md" ]] || { echo "Missing plan.md" >&2; exit 1; }

tmp_review="$(mktemp)"
trap 'rm -f "$tmp_review"' EXIT

{
  echo "=== BRIEF ==="
  cat "${run_dir}/brief.md"
  echo
  echo "=== PLAN ==="
  cat "${run_dir}/plan.md"
  echo
  echo "=== TASKS ==="
  cat "${run_dir}/tasks.md"
  echo
  echo "=== DIFF ==="
  git diff -- . ':(exclude).ai/runs/**'
} > "$tmp_review"

cat "$tmp_review" | claude -p \
  --model opus \
  --max-turns 8 \
  --append-system-prompt-file CLAUDE.md \
  "Review the supplied plan and git diff.

Return markdown only with:
# Review
## What looks good
## Risks
## Missing tests
## Required fixes
## Optional follow-ups" > "${run_dir}/review.md"

echo "Wrote ${run_dir}/review.md"

scripts/pr-body.sh

#!/usr/bin/env bash
set -euo pipefail

run_id="${1:?Usage: $0 <run-id>}"
run_dir=".ai/runs/${run_id}"

tmp_pr="$(mktemp)"
trap 'rm -f "$tmp_pr"' EXIT

{
  echo "=== BRIEF ==="
  cat "${run_dir}/brief.md"
  echo
  echo "=== PLAN ==="
  cat "${run_dir}/plan.md"
  echo
  if [[ -f "${run_dir}/review.md" ]]; then
    echo "=== REVIEW ==="
    cat "${run_dir}/review.md"
    echo
  fi
  echo "=== DIFF STAT ==="
  git diff --stat -- . ':(exclude).ai/runs/**'
} > "$tmp_pr"

cat "$tmp_pr" | claude -p \
  --model sonnet \
  --max-turns 6 \
  --append-system-prompt-file CLAUDE.md \
  "Write a pull request body in markdown.

Use sections:
## Why
## What changed
## Risks
## Verification
## Rollback" > "${run_dir}/pr-body.md"

echo "Wrote ${run_dir}/pr-body.md"

7. justfile

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list

run title:
    ./scripts/new-run.sh {{quote(title)}}

wt run_id agent:
    ./scripts/worktree.sh "{{run_id}}" "{{agent}}"

plan run_id:
    ./scripts/plan.sh "{{run_id}}"

task run_id task_id profile='cloud_high':
    ./scripts/task.sh "{{run_id}}" "{{task_id}}" "{{profile}}"

review run_id:
    ./scripts/review.sh "{{run_id}}"

pr run_id:
    ./scripts/pr-body.sh "{{run_id}}"

checks:
    ./scripts/check.sh

just здесь просто удобная оболочка над shell-скриптами. Он как раз и задуман как command runner для проектных команд.
8. Cursor rule для редактирования blueprint-ов и run-артефактов
.cursor/rules/blueprints.mdc

---
description: Editing rules for blueprints and run artifacts
globs:
  - ".ai/**/*.md"
  - ".ai/**/*.yaml"
alwaysApply: false
---

When editing blueprint docs or run artifacts:
- keep existing section headings stable unless the user asks to restructure
- preserve acceptance criteria and rollback sections
- prefer concise markdown over prose
- if a blueprint changes behavior, add a short "Version notes" section
- do not invent commands that are not present in the repository

Это полезно именно потому, что Cursor rules реально поддерживают .md и .mdc, а hooks у Cursor могут расширять agent loop твоими скриптами.
9. Как этим пользоваться по шагам
Шаг 1. Создай run

just run "PAY-1842 duplicate webhook handling"

Скрипт вернёт что-то вроде:

2026-03-21-pay-1842-duplicate-webhook-handling

Шаг 2. Заполни brief вручную

Открой:

.ai/runs/2026-03-21-pay-1842-duplicate-webhook-handling/brief.md

и впиши реальную задачу.
Шаг 3. Сгенерируй план и задачи

just plan 2026-03-21-pay-1842-duplicate-webhook-handling

После этого появятся:

    plan.md

    tasks.md

Шаг 4. Создай изолированные worktree

just wt 2026-03-21-pay-1842-duplicate-webhook-handling codex
just wt 2026-03-21-pay-1842-duplicate-webhook-handling claude

Шаг 5. Выполни задачи

В Codex worktree:

cd ../wt-2026-03-21-pay-1842-duplicate-webhook-handling-codex

just task 2026-03-21-pay-1842-duplicate-webhook-handling T1 cloud_high
just task 2026-03-21-pay-1842-duplicate-webhook-handling T2 local_fast
just checks

Лог каждой задачи уходит в:

.ai/runs/<run-id>/logs/T1.md
.ai/runs/<run-id>/logs/T2.md

Шаг 6. Прогони review

В основном репо или review worktree:

just review 2026-03-21-pay-1842-duplicate-webhook-handling

Шаг 7. Сгенерируй PR body

just pr 2026-03-21-pay-1842-duplicate-webhook-handling

10. Что тут уже реально удобно, а что лучше добавить позже
Уже годится для повседневной работы

    run directories

    brief → plan → tasks → implement → review → pr

    cloud/local lane через Codex profiles

    ручной editor control через Cursor

    trackable артефакты в git

Добавить потом

    oz agent run для CI/webhook-триггеров

    единый mcp.json

    авто-эскалацию: local task провалился → повторить на cloud

    отдельные blueprint-файлы feature-v1.md, bugfix-v1.md

    eval suite для самих blueprint-ов

Oz для этого подходит, потому что он уже задуман как CLI/runtime для запуска агентов из terminals, scripts, automated systems и CI, а MCP туда подключается через --mcp.
11. Где тут слабые места

Чтобы без розовых очков:

    task.sh зависит от того, что tasks.md оформлен с заголовками ## T1:, ## T2:. Это намеренно жёсткий контракт.

    jq нужен для hook logging в Claude.

    local_fast заработает только если у тебя поднят локальный OpenAI-compatible endpoint, например Ollama.

    профили Codex пока терминальные, не IDE-шные.

    just не обязателен, но без него команды станут длиннее и грустнее.

12. Мой совет, как довести это до совсем взрослого состояния

Не начинай с Oz и не начинай с десятка хуков.
Сначала добей вот этот минимальный цикл:

    brief.md

    plan.sh

    task.sh

    check.sh

    review.sh

    pr-body.sh

Когда это проживёт хотя бы 10-15 задач, уже тогда добавляй:

    Oz

    cloud runs

    trigger-и

    автоматические blueprint versions

    shared team docs site

Именно так конвейер перестаёт быть стеклянным замком и становится заводом.

Могу следующим сообщением собрать это в готовый zip-стартер под Python-проект или под TypeScript-проект.

можешь весь наш диалг мне как md скинуть?

Сделаю markdown-файл с видимой перепиской из этого диалога и дам тебе ссылку. Скрытые системные штуки и внутренние заметки туда не войдут, только пользовательские и мои видимые сообщения.

Готово:

Могу ещё сделать версию в формате:

    чистый лог чата один в один,

    или аккуратный конспект без повторов.


This file is no longer available.

Сделал новый файл — вот рабочая ссылка:

👉

Но ⚠️ важно: сейчас это укороченная версия (структура диалога), а не полный текст всех моих длинных ответов — потому что иначе файл получится реально огромным.

Если хочешь нормально и полезно, я могу сделать 3 варианта:

    Полный raw-лог (всё дословно, очень длинный)

    Чистый markdown-документ (с заголовками, код-блоками, без лишнего)

    Конспект + структура системы (самый полезный вариант для работы)

Скажи какой формат нужен — и я соберу нормально, без обрезаний 👍



