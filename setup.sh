#!/bin/bash
# Claude Second Brain — one-line setup
#
# Usage:
#   git clone https://github.com/jason-c-dev/claude-second-brain.git my-agent
#   cd my-agent && ./setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Claude Second Brain — Setup ==="
echo ""

# ── Check prerequisites ──────────────────────────────────────────────

MISSING=""

if ! command -v bun &>/dev/null; then
  MISSING="$MISSING bun"
fi

if ! command -v python3 &>/dev/null; then
  MISSING="$MISSING python3"
fi

if ! command -v claude &>/dev/null; then
  MISSING="$MISSING claude"
fi

if [ -n "$MISSING" ]; then
  echo "Missing required tools:$MISSING"
  echo ""
  echo "Install:"
  echo "  bun       — https://bun.sh"
  echo "  python3   — comes with macOS / brew install python3"
  echo "  claude    — npm install -g @anthropic-ai/claude-code"
  echo ""
  exit 1
fi

echo "[1/8] Prerequisites OK (bun, python3, claude)"

# ── Install dependencies ─────────────────────────────────────────────

echo "[2/8] Installing dependencies..."
(cd .channels/webhook-channel && bun install --silent)
(cd .tools/voice-tools && bun install --silent)
echo "      Dependencies installed."

# ── Scaffold directories ─────────────────────────────────────────────

echo "[3/8] Scaffolding directories..."
mkdir -p raw wiki output .config .channels/telegram
touch .config/compiled-raw.txt
echo "      Directories ready."

# ── Configuration ────────────────────────────────────────────────────

if [ ! -f config.env ]; then
  cp config.example.env config.env
  echo "[4/8] Created config.env from template."
else
  echo "[4/8] config.env already exists — skipping."
fi

# ── Telegram bot token ──────────────────────────────────────────────

if [ ! -f .channels/telegram/.env ]; then
  echo ""
  echo "[5/8] Telegram setup"
  echo "      Create a bot via @BotFather on Telegram and paste the token below."
  echo "      (press Enter to skip if you don't have one yet)"
  echo ""
  read -p "      Bot token: " BOT_TOKEN

  if [ -n "$BOT_TOKEN" ]; then
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > .channels/telegram/.env
    echo "      Bot token saved."

    # Prompt for chat ID since we have their attention
    echo ""
    echo "      Now enter your personal Telegram chat ID."
    echo "      Find it by messaging @userinfobot on Telegram."
    echo ""
    read -p "      Chat ID: " CHAT_ID

    if [ -n "$CHAT_ID" ]; then
      # Update config.env with the chat ID
      if grep -q "TELEGRAM_CHAT_ID=YOUR_CHAT_ID" config.env 2>/dev/null; then
        sed -i '' "s/TELEGRAM_CHAT_ID=YOUR_CHAT_ID/TELEGRAM_CHAT_ID=$CHAT_ID/" config.env
        echo "      Chat ID saved to config.env"
      fi

      # Create access.json with this user on the allowlist
      cat > .channels/telegram/access.json << EOFJSON
{
  "dmPolicy": "pairing",
  "allowFrom": [
    "$CHAT_ID"
  ],
  "groups": {},
  "pending": {}
}
EOFJSON
      echo "      Access config created — your chat ID is on the allowlist."
    fi
  else
    echo "      Skipped — you can set this up later. See README for details."
  fi
else
  echo "[5/8] Telegram bot token already configured."
  # Ensure access.json exists if we have a chat ID in config.env
  if [ ! -f .channels/telegram/access.json ] && [ -f config.env ]; then
    EXISTING_CHAT_ID=$(grep "^TELEGRAM_CHAT_ID=" config.env 2>/dev/null | cut -d= -f2)
    if [ -n "$EXISTING_CHAT_ID" ] && [ "$EXISTING_CHAT_ID" != "YOUR_CHAT_ID" ]; then
      cat > .channels/telegram/access.json << EOFJSON
{
  "dmPolicy": "pairing",
  "allowFrom": [
    "$EXISTING_CHAT_ID"
  ],
  "groups": {},
  "pending": {}
}
EOFJSON
      echo "      Created access.json from config.env chat ID."
    fi
  fi
fi

# ── MCP configuration ───────────────────────────────────────────────

if [ ! -f .mcp.json ]; then
  # Find the Telegram plugin cache path
  TELEGRAM_PLUGIN=""
  PLUGIN_BASE="$HOME/.claude/plugins/cache/claude-plugins-official/telegram"
  if [ -d "$PLUGIN_BASE" ]; then
    TELEGRAM_PLUGIN=$(ls -d "$PLUGIN_BASE"/*/ 2>/dev/null | sort -V | tail -1)
  fi

  cp .mcp.example.json .mcp.json

  STATE_DIR="$SCRIPT_DIR/.channels/telegram"
  python3 -c "
import json, sys
with open('.mcp.json') as f:
    cfg = json.load(f)
plugin_path = sys.argv[1]
state_dir = sys.argv[2]
if plugin_path:
    cfg['mcpServers']['telegram']['args'][2] = plugin_path.rstrip('/')
    cfg['mcpServers']['telegram']['env']['TELEGRAM_STATE_DIR'] = state_dir
else:
    del cfg['mcpServers']['telegram']
with open('.mcp.json', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" "${TELEGRAM_PLUGIN}" "${STATE_DIR}"

  if [ -n "$TELEGRAM_PLUGIN" ]; then
    echo "[6/8] Created .mcp.json — Telegram plugin found."
  else
    echo "[6/8] Created .mcp.json — Telegram plugin not found."
    echo "      Install it first:  claude  then  /plugin install telegram"
    echo "      Then re-run:  ./setup.sh"
  fi

  # Auto-detect whisper model path
  WHISPER_MODEL=""
  if [ -f "/opt/homebrew/share/whisper-cpp/models/ggml-base.en.bin" ]; then
    WHISPER_MODEL="/opt/homebrew/share/whisper-cpp/models/ggml-base.en.bin"
  elif [ -f "$HOME/.local/share/whisper-cpp/models/ggml-base.en.bin" ]; then
    WHISPER_MODEL="$HOME/.local/share/whisper-cpp/models/ggml-base.en.bin"
  fi

  if [ -n "$WHISPER_MODEL" ]; then
    python3 -c "
import json
with open('.mcp.json') as f:
    cfg = json.load(f)
cfg['mcpServers']['voice-tools']['env']['STT_MODEL'] = '$WHISPER_MODEL'
with open('.mcp.json', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
"
    echo "      Whisper model auto-detected: $WHISPER_MODEL"
  fi
else
  echo "[6/8] .mcp.json already exists — skipping."
fi

# ── Cron jobs ────────────────────────────────────────────────────────

# Read the webhook port from .mcp.json (source of truth)
WEBHOOK_PORT="8790"
if [ -f .mcp.json ]; then
  WEBHOOK_PORT=$(python3 -c "
import json
with open('.mcp.json') as f:
    cfg = json.load(f)
print(cfg.get('mcpServers',{}).get('webhook-channel',{}).get('env',{}).get('WEBHOOK_PORT','8790'))
" 2>/dev/null || echo "8790")
fi

if crontab -l 2>/dev/null | grep -q "dream-memory"; then
  echo "[7/8] Cron jobs already installed — skipping."
else
  # Generate crontab entries with the correct port
  CRON_ENTRIES="3 2 * * * curl -s -X POST http://127.0.0.1:${WEBHOOK_PORT}/dream-memory -H 'Content-Type: application/json' -d '{\"task\":\"dream-memory\"}'
33 3 * * * curl -s -X POST http://127.0.0.1:${WEBHOOK_PORT}/dream-wiki -H 'Content-Type: application/json' -d '{\"task\":\"dream-wiki\"}'"

  (crontab -l 2>/dev/null; echo "$CRON_ENTRIES") | crontab -
  echo "[7/8] Cron jobs installed (port ${WEBHOOK_PORT}, dreams at 2:03 AM + 3:33 AM)."
  echo "      Edit times with:  crontab -e"
fi

# ── Optional tools check ─────────────────────────────────────────────

echo "[8/8] Optional tools"

# Voice transcription
if command -v whisper-cli &>/dev/null; then
  echo "      ✓ whisper-cli (voice transcription) — installed"
elif command -v ffmpeg &>/dev/null; then
  echo "      - whisper-cli not installed (ffmpeg found)"
  echo "        To enable voice: brew install whisper-cpp && curl -L -o /opt/homebrew/share/whisper-cpp/models/ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
else
  echo "      - voice transcription not installed"
  echo "        brew install ffmpeg whisper-cpp"
  echo "        curl -L -o /opt/homebrew/share/whisper-cpp/models/ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
fi

# YouTube/media transcripts
if command -v yt-dlp &>/dev/null; then
  echo "      ✓ yt-dlp (YouTube transcripts / media ingestion) — installed"
else
  echo "      - yt-dlp not installed"
  echo "        To ingest YouTube / podcasts / video transcripts: brew install yt-dlp"
fi

# ── Done ─────────────────────────────────────────────────────────────

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo ""

# Check what's still needed
NEEDS_PLUGIN=false
NEEDS_TOKEN=false
NEEDS_ACCESS=false

if [ ! -f .mcp.json ] || ! python3 -c "import json; json.load(open('.mcp.json'))['mcpServers']['telegram']" 2>/dev/null; then
  NEEDS_PLUGIN=true
fi
if [ ! -f .channels/telegram/.env ]; then
  NEEDS_TOKEN=true
fi

if $NEEDS_PLUGIN || $NEEDS_TOKEN; then
  echo "  Remaining Telegram setup:"
  if $NEEDS_PLUGIN; then
    echo "    1. Start a plain Claude session:  claude"
    echo "    2. Install the plugin:  /plugin install telegram"
    echo "    3. Exit and re-run:  ./setup.sh"
    echo ""
  fi
  if $NEEDS_TOKEN; then
    echo "    - Create a bot via @BotFather and re-run:  ./setup.sh"
    echo ""
  fi
else
  if [ -f .channels/telegram/access.json ]; then
    echo "  Telegram is fully configured — ready to launch!"
    echo ""
  else
    echo "  1. Pair your Telegram account (one-time):"
    echo "     Start a plain Claude session:  claude"
    echo "     Then run:  /telegram:access"
    echo "     Exit when done."
    echo ""
  fi
fi

echo "  Install Obsidian Skills plugin (required for proper wiki links):"
echo "     Start a plain Claude session:  claude"
echo "     /plugin marketplace add kepano/obsidian-skills"
echo "     /plugin install obsidian@obsidian-skills"
echo "     Exit the session."
echo ""
echo "  Launch:"
echo "     ./start.sh"
echo ""
echo "  (Optional) Open this directory as an Obsidian vault"
echo "     All infrastructure is in dot-directories (invisible to Obsidian)"
echo "     Install Obsidian Web Clipper to capture articles into raw/"
echo ""
