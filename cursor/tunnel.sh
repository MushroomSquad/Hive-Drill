#!/usr/bin/env bash
# Прокидывает локальный LLM endpoint наружу через HTTPS-туннель
# Нужно для Cursor — он требует публичный HTTPS URL
# Поддерживает: cloudflared (бесплатно, рекомендуется) или ngrok
set -euo pipefail

BACKEND="${1:-tabbyapi}"
TUNNEL="${2:-cloudflared}"

case "$BACKEND" in
  tabbyapi)  LOCAL_PORT=33931 ;;
  llamacpp)  LOCAL_PORT=33831 ;;
  *)         LOCAL_PORT="${1:-33931}" ;;
esac

echo "=== HTTPS Туннель ==="
echo "Локальный порт: $LOCAL_PORT"
echo "Туннель: $TUNNEL"
echo ""

case "$TUNNEL" in
  cloudflared)
    if ! command -v cloudflared &>/dev/null; then
      echo "Устанавливаю cloudflared..."
      if command -v apt-get &>/dev/null; then
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | \
          sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | \
          sudo tee /etc/apt/sources.list.d/cloudflared.list
        sudo apt-get update -q && sudo apt-get install -y cloudflared
      elif command -v brew &>/dev/null; then
        brew install cloudflare/cloudflare/cloudflared
      else
        echo "Скачай cloudflared вручную: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
        exit 1
      fi
    fi
    echo "Запускаю туннель (Ctrl+C для остановки)..."
    echo "URL появится ниже. Скопируй его и вставь в Cursor Settings → Models → Override OpenAI Base URL"
    echo "(добавь /v1 в конец)"
    echo ""
    cloudflared tunnel --url "http://localhost:$LOCAL_PORT"
    ;;

  ngrok)
    if ! command -v ngrok &>/dev/null; then
      echo "ngrok не найден. Установи: https://ngrok.com/download"
      exit 1
    fi
    echo "Запускаю ngrok туннель (Ctrl+C для остановки)..."
    echo "URL появится в ngrok UI: http://localhost:4040"
    echo ""
    ngrok http "$LOCAL_PORT"
    ;;

  *)
    echo "Неизвестный туннель: $TUNNEL"
    echo "Используй: cloudflared (рекомендуется) или ngrok"
    exit 1
    ;;
esac
