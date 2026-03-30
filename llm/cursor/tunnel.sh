#!/usr/bin/env bash
# Forward local LLM endpoint externally via HTTPS tunnel
# Required for Cursor — it requires a public HTTPS URL
# Supports: cloudflared (free, recommended) or ngrok
set -euo pipefail

BACKEND="${1:-tabbyapi}"
TUNNEL="${2:-cloudflared}"

case "$BACKEND" in
  tabbyapi)  LOCAL_PORT=33931 ;;
  llamacpp)  LOCAL_PORT=33831 ;;
  *)         LOCAL_PORT="${1:-33931}" ;;
esac

echo "=== HTTPS Tunnel ==="
echo "Local port: $LOCAL_PORT"
echo "Tunnel: $TUNNEL"
echo ""

case "$TUNNEL" in
  cloudflared)
    if ! command -v cloudflared &>/dev/null; then
      echo "Installing cloudflared..."
      if command -v apt-get &>/dev/null; then
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | \
          sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | \
          sudo tee /etc/apt/sources.list.d/cloudflared.list
        sudo apt-get update -q && sudo apt-get install -y cloudflared
      elif command -v brew &>/dev/null; then
        brew install cloudflare/cloudflare/cloudflared
      else
        echo "Download cloudflared manually: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
        exit 1
      fi
    fi
    echo "Starting tunnel (Ctrl+C to stop)..."
    echo "URL will appear below. Copy it and paste into Cursor Settings → Models → Override OpenAI Base URL"
    echo "(add /v1 at the end)"
    echo ""
    cloudflared tunnel --url "http://localhost:$LOCAL_PORT"
    ;;

  ngrok)
    if ! command -v ngrok &>/dev/null; then
      echo "ngrok not found. Install: https://ngrok.com/download"
      exit 1
    fi
    echo "Starting ngrok tunnel (Ctrl+C to stop)..."
    echo "URL will appear in ngrok UI: http://localhost:4040"
    echo ""
    ngrok http "$LOCAL_PORT"
    ;;

  *)
    echo "Unknown tunnel: $TUNNEL"
    echo "Use: cloudflared (recommended) or ngrok"
    exit 1
    ;;
esac
