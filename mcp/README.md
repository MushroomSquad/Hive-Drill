# MCP Servers — Common tool bus

MCP (Model Context Protocol) — common glue for all agents.
One set of servers connects to **Cursor**, **Codex**, **Claude Code**, and **Warp**.

## Installation

```bash
./scripts/init.sh --mcp    # install MCP servers
```

or manually:
```bash
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-memory
```

## Connecting to each tool

### Cursor
`~/.cursor/mcp.json` or `Settings → MCP`:
```json
{ "mcpServers": <content from mcp/config.json mcpServers> }
```

### Claude Code
`~/.claude/claude_desktop_config.json` or `settings.json`:
```json
{ "mcpServers": <content from mcp/config.json mcpServers> }
```

### Codex
Add `[mcp]` section to `.codex/config.toml`:
```toml
[mcp.servers.github]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
```

### Warp
Warp → Settings → MCP → Add server → paste config.

## Servers

| Server | Purpose | Required |
|--------|---------|:--------:|
| `github` | Issues, PRs, code search | ✅ |
| `filesystem` | File operations with validation | ✅ |
| `memory` | Cross-session agent context | ✅ |
| `postgres` | DB schema, readonly queries | opt. |
| `playwright` | Browser automation, E2E | opt. |
| `linear` | Task tracker | opt. |

## Environment variables

Create `.env` from `.env.example`:
```
GITHUB_TOKEN=ghp_...
DATABASE_URL=postgresql://...
LINEAR_API_KEY=lin_api_...
```
