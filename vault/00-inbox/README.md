# 📥 Inbox

Новые задачи создаются здесь через шаблон `brief.md`.

**Шаги:**
1. Создай задачу: `just new TASK-ID`
2. Заполни открывшийся файл `TASK-ID.md`
3. Смени `status: draft` → `status: ready`
4. Запусти pipeline: `just go TASK-ID`

Файл автоматически переместится в `01-active/` когда pipeline стартует.
