#!/bin/bash
# Claude Second Brain — launcher
#
# Sources your config.env and launches Claude Code with the correct flags.
# The --dangerously-load-development-channels flags register Telegram and
# webhook-channel as MCP servers that push events INTO your Claude session.
#
# IMPORTANT: Each channel needs its own flag. Comma-separated does NOT work.
# Using plugin: instead of server: drops messages arriving mid-response
# (no queue, no retry). The server: path via .mcp.json fixes this.
# See: https://github.com/anthropics/claude-plugins-official/issues/1143

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load configuration
if [ -f config.env ]; then
  source config.env
fi

claude \
  --dangerously-load-development-channels server:telegram \
  --dangerously-load-development-channels server:webhook-channel \
  --permission-mode auto
