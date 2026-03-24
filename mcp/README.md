# MCP Servers — Общая шина инструментов

MCP (Model Context Protocol) — общий клей для всех агентов.
Один набор серверов подключается в **Cursor**, **Codex**, **Claude Code** и **Warp**.

## Установка

```bash
./scripts/init.sh --mcp    # установить MCP серверы
```

или вручную:
```bash
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-memory
```

## Подключение в каждый инструмент

### Cursor
`~/.cursor/mcp.json` или `Settings → MCP`:
```json
{ "mcpServers": <содержимое mcp/config.json mcpServers> }
```

### Claude Code
`~/.claude/claude_desktop_config.json` или `settings.json`:
```json
{ "mcpServers": <содержимое mcp/config.json mcpServers> }
```

### Codex
Добавить в `.codex/config.toml` секцию `[mcp]`:
```toml
[mcp.servers.github]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
```

### Warp
Warp → Settings → MCP → Add server → вставить конфиг.

## Серверы

| Сервер | Назначение | Обязательный |
|--------|-----------|:----------:|
| `github` | Issues, PRs, code search | ✅ |
| `filesystem` | Файловые операции с валидацией | ✅ |
| `memory` | Cross-session контекст агентов | ✅ |
| `postgres` | Схема БД, readonly queries | опц. |
| `playwright` | Browser automation, E2E | опц. |
| `linear` | Трекер задач | опц. |

## Переменные окружения

Создай `.env` из `.env.example`:
```
GITHUB_TOKEN=ghp_...
DATABASE_URL=postgresql://...
LINEAR_API_KEY=lin_api_...
```
