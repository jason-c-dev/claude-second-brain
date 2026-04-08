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

echo "[1/5] Prerequisites OK (bun, python3, claude)"

# ── Install dependencies ─────────────────────────────────────────────

echo "[2/5] Installing dependencies..."
(cd .channels/webhook-channel && bun install --silent)
(cd .tools/voice-tools && bun install --silent)
echo "      Dependencies installed."

# ── Scaffold directories ─────────────────────────────────────────────

echo "[3/5] Scaffolding directories..."
mkdir -p raw wiki output .config
touch .config/compiled-raw.txt
echo "      Directories ready."

# ── Configuration ────────────────────────────────────────────────────

if [ ! -f config.env ]; then
  cp config.example.env config.env
  echo "[4/5] Created config.env from template — edit it with your values."
else
  echo "[4/5] config.env already exists — skipping."
fi

# ── Whisper model (optional) ─────────────────────────────────────────

echo "[5/5] Voice transcription setup (optional)"
if command -v whisper-cli &>/dev/null; then
  echo "      whisper-cli found."
elif command -v ffmpeg &>/dev/null; then
  echo "      ffmpeg found but whisper-cli not installed."
  echo "      To enable voice: https://github.com/ggerganov/whisper.cpp"
else
  echo "      ffmpeg and whisper-cli not found."
  echo "      Voice transcription requires both. Install if needed:"
  echo "        brew install ffmpeg"
  echo "        https://github.com/ggerganov/whisper.cpp"
fi

# ── Done ─────────────────────────────────────────────────────────────

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit config.env with your Telegram chat ID and other settings"
echo ""
echo "  2. Set up Telegram (one-time):"
echo "     - Create a bot via @BotFather on Telegram"
echo "     - In a Claude session: /plugin install telegram"
echo "     - Then: /telegram:access"
echo "     - See: https://docs.anthropic.com/en/docs/claude-code/telegram"
echo ""
echo "  3. Install cron jobs for overnight dreams:"
echo "     (crontab -l 2>/dev/null; cat .config/crontab) | crontab -"
echo ""
echo "  4. Launch:"
echo "     ./start.sh"
echo ""
echo "  5. (Optional) Open this directory as an Obsidian vault"
echo "     - All infrastructure is in dot-directories (invisible to Obsidian)"
echo "     - Install Obsidian Web Clipper to capture articles into raw/"
echo ""
