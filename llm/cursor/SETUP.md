# Connecting to Cursor

## Cursor Limitation

Cursor requires a **public HTTPS URL** for custom endpoints.
`localhost` and LAN IP do not work directly.

That's why you need a tunnel.

## Steps

### 1. Start the local stack

```bash
# Run the code model
./profiles/tabbyapi-coder.sh

# Verify
curl http://localhost:33931/v1/models
```

### 2. Create a tunnel

```bash
# cloudflared (recommended, free)
./cursor/tunnel.sh tabbyapi cloudflared
```

After starting, a URL like this will appear in the console:
```
https://something-random.trycloudflare.com
```

### 3. Configure Cursor

1. Open `Cursor Settings` → `Models`
2. Scroll down to `OpenAI API Key`
3. Enable **Override OpenAI Base URL**
4. Enter the tunnel URL + `/v1`:
   ```
   https://something-random.trycloudflare.com/v1
   ```
5. API Key: any non-empty string (e.g. `local`)
6. Click `+ Add model`, enter a model name from the list:
   ```
   Qwen2.5-Coder-7B-Instruct-exl2
   ```
7. Select this model in chat

### 4. Troubleshooting

| Symptom | Solution |
|---------|----------|
| Agent mode crashes with format error | Switch to **Ask mode** |
| Timeout | Enable **HTTP/1.1** in settings |
| "model not found" | Check the exact name via `curl .../v1/models` |
| Tunnel dropped | Cloudflared URL is temporary — restart the tunnel and update the URL in Cursor |

## Persistent Tunnel (optional)

For a stable URL, register a free domain in Cloudflare and set up a Named Tunnel:

```bash
cloudflared tunnel login
cloudflared tunnel create local-llm
cloudflared tunnel route dns local-llm llm.yourdomain.com
```

Then the URL will be permanent: `https://llm.yourdomain.com/v1`

## Security

The tunnel makes the endpoint public. If you don't want that:
- Use ngrok with a password (`ngrok http --auth "user:pass" 33931`)
- Or add an API key to the TabbyAPI config and pass it through Cursor

## Cursor Alternative

For local work without a tunnel use:
- **Open WebUI** — `harbor up openwebui` → `http://localhost:8080`
- **Continue.dev** (VSCode) — can work with local endpoint directly
