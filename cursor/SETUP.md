# Подключение к Cursor

## Ограничение Cursor

Cursor требует **публичный HTTPS URL** для кастомных endpoint'ов.
`localhost` и LAN IP напрямую не работают.

Поэтому нужен туннель.

## Шаги

### 1. Поднять локальный стек

```bash
# Запустить кодовую модель
./profiles/tabbyapi-coder.sh

# Проверить
curl http://localhost:33931/v1/models
```

### 2. Пробросить туннель

```bash
# cloudflared (рекомендуется, бесплатно)
./cursor/tunnel.sh tabbyapi cloudflared
```

После запуска в консоли появится URL вида:
```
https://something-random.trycloudflare.com
```

### 3. Настроить Cursor

1. Открыть `Cursor Settings` → `Models`
2. Прокрутить вниз до `OpenAI API Key`
3. Включить **Override OpenAI Base URL**
4. Вставить URL туннеля + `/v1`:
   ```
   https://something-random.trycloudflare.com/v1
   ```
5. API Key: можно любой непустой строкой (например `local`)
6. Нажать `+ Add model`, ввести имя модели из списка:
   ```
   Qwen2.5-Coder-7B-Instruct-exl2
   ```
7. Выбрать эту модель в чате

### 4. Если не работает

| Симптом | Решение |
|---------|---------|
| Agent mode падает с ошибкой формата | Переключись на **Ask mode** |
| Таймаут | Включи **HTTP/1.1** в настройках |
| "model not found" | Проверь точное имя через `curl .../v1/models` |
| Туннель отвалился | URL cloudflared временный — перезапусти туннель и обнови URL в Cursor |

## Постоянный туннель (опционально)

Для стабильного URL зарегистрируй бесплатный домен в Cloudflare и настрой Named Tunnel:

```bash
cloudflared tunnel login
cloudflared tunnel create local-llm
cloudflared tunnel route dns local-llm llm.yourdomain.com
```

Тогда URL будет постоянным: `https://llm.yourdomain.com/v1`

## Безопасность

Туннель делает endpoint публичным. Если не хочешь этого:
- Используй ngrok с паролем (`ngrok http --auth "user:pass" 33931`)
- Или добавь API-ключ в TabbyAPI config и передавай его через Cursor

## Альтернатива Cursor

Для локальной работы без туннеля используй:
- **Open WebUI** — `harbor up openwebui` → `http://localhost:8080`
- **Continue.dev** (VSCode) — умеет работать с локальным endpoint напрямую
