# Local LLM Stack for Cursor IDE

Локальный стек для запуска LLM с OpenAI-compatible API и подключения к Cursor/любому IDE-агенту.

## Железо / Целевое окружение

| Компонент | Значение |
|-----------|----------|
| GPU | RTX 4070 (12 GB VRAM) |
| RAM | 49 GB |
| CPU | Ryzen 5600X |
| OS | Linux / WSL2 |

## Архитектура

```
Cursor / IDE
  └─> публичный HTTPS-туннель (cloudflared / ngrok)
        └─> Harbor (оркестратор)
              ├─> TabbyAPI + ExLlamaV2  ← основной стек (быстрый)
              ├─> llama.cpp + GGUF      ← резервный стек (надёжный)
              └─> AirLLM               ← тяжёлые модели (>VRAM)
```

## Стеки

### Основной — Harbor + TabbyAPI + EXL2 (рекомендуется)
- Максимальная скорость на consumer GPU
- OpenAI-compatible API из коробки
- Endpoint: `http://localhost:33931/v1`

### Резервный — Harbor + llama.cpp + GGUF
- Надёжнее, router mode для нескольких моделей
- Flash Attention, prefix cache, speculative decoding
- Endpoint: `http://localhost:33831/v1`

### Тяжёлый — Harbor + AirLLM
- Для моделей, которые не влезают в VRAM
- Layer-wise загрузка, 4-bit/8-bit compression
- Endpoint: `http://localhost` (порт по конфигу Harbor)

## Рекомендуемые модели

| Назначение | Модель | Квант | VRAM |
|------------|--------|-------|------|
| Кодинг (daily) | Qwen2.5-Coder-7B-Instruct-exl2 | 6_5 | ~8.6 GB @ 16k |
| ТЗ / доки / архитектура | Qwen2.5-14B-Instruct-exl2 | 4_25 | ~10.1 GB @ 4k |
| Быстрый резерв | Meta-Llama-3.1-8B-Instruct-exl2 | 6_5 | ~8 GB |
| Тяжёлый (по запросу) | Qwen2.5-Coder-32B-Instruct-exl2 | 4_0 | >12 GB → AirLLM |

## Быстрый старт

```bash
# 1. Установить Harbor
./setup/install.sh

# 2. Проверить зависимости
./setup/check.sh

# 3. Скачать основную модель (кодер)
./models/download-coder.sh

# 4. Поднять стек
./profiles/tabbyapi-coder.sh

# 5. Проверить endpoint
curl http://localhost:33931/v1/models
```

Подробнее:
- [Установка](setup/install.sh)
- [Скачивание моделей](models/)
- [Профили запуска](profiles/)
- [Системные промпты](prompts/)
- [Подключение к Cursor](cursor/SETUP.md)
