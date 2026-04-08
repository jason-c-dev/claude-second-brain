# Claude Second Brain

A complete autonomous [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agent that maintains a personal knowledge base, runs overnight dream cycles, and stays reachable via Telegram — batteries included.

Built on the [Karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern and inspired by Anthropic's [Auto Dream](https://github.com/anthropics/claude-code/blob/main/docs/auto-dream.md) memory system.

## What This Is

An always-on AI second brain that:

- **Maintains a wiki knowledge base** — raw sources go in, curated articles come out (the Karpathy pattern)
- **Dreams overnight** — two cron-triggered dream cycles consolidate memory and compile new wiki articles while you sleep
- **Talks to you on Telegram** — text, voice messages, images, documents
- **Transcribes voice locally** — whisper.cpp, fully on-device, no cloud APIs
- **Works with Obsidian** — open the repo as a vault, get graph view of your knowledge for free
- **Enforces good behaviour** — a deterministic hook ensures Claude always acknowledges your Telegram messages before doing anything else

All infrastructure lives in dot-directories (`.channels/`, `.tools/`, `.hooks/`, `.claude/`, `.config/`) so Obsidian ignores them. Only knowledge content (`raw/`, `wiki/`, `output/`) and top-level files appear in your vault and graph view.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Telegram    │────▶│  Claude Code  │────▶│  wiki/          │
│  (text/voice)│     │  + CLAUDE.md  │     │  (curated KB)   │
└─────────────┘     │  + skills     │     └─────────────────┘
                    │  + subagents  │
┌─────────────┐     │              │     ┌─────────────────┐
│  Cron        │────▶│              │────▶│  memory/        │
│  (2:03/3:33) │     │              │     │  (Claude's own)  │
└──────┬──────┘     └──────────────┘     └─────────────────┘
       │                   ▲
       ▼                   │
┌─────────────┐     ┌──────────────┐
│  webhook-    │────▶│  MCP server  │
│  channel     │     │  (push IN)   │
│  :8790       │     └──────────────┘
└─────────────┘

┌─────────────┐     ┌──────────────┐
│  Voice msg   │────▶│  voice-tools │
│  (Telegram)  │     │  (whisper.cpp)│
└─────────────┘     └──────────────┘
```

**How events flow:**
- **Telegram messages** arrive via the Telegram MCP server (push IN to the session)
- **Dream cycles** fire via cron → curl → webhook-channel → MCP notification → Claude routes to skill
- **Skills** spawn subagents with fresh context (no session bleed) to do the actual work
- **Results** go to Telegram (reports) and wiki/log.md (audit trail)

## Features

| Feature | What It Does |
|---------|-------------|
| **LLM Wiki** | Raw sources compiled into curated, cross-linked wiki articles. The Karpathy pattern. |
| **Dream Cycles** | Overnight memory consolidation + wiki compilation via cron-triggered subagents |
| **Telegram** | Text, voice, images, documents. Always reachable. |
| **Voice Transcription** | whisper.cpp — fully local, no cloud APIs |
| **Telegram Gate Hook** | Deterministic enforcement: Claude must acknowledge messages before doing anything else |
| **Obsidian Compatible** | Dot-directories invisible to Obsidian. Wiki links render as graph. |
| **Subagent Architecture** | Dreams use fresh-context subagents to avoid the self-evaluation trap |
| **Compiled Manifest** | `.config/compiled-raw.txt` prevents reprocessing — O(1) inventory, not O(n) log scanning |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Pro or Max subscription)
- [Bun](https://bun.sh) (JavaScript runtime)
- Python 3 (for the Telegram gate hook — standard library only, no pip)
- A Telegram bot token (from [@BotFather](https://t.me/BotFather))
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) + [ffmpeg](https://ffmpeg.org/) (optional — for voice transcription)
- [Obsidian](https://obsidian.md/) (optional but recommended)

## Quick Start

```bash
git clone https://github.com/jason-c-dev/claude-second-brain.git my-brain
cd my-brain && ./setup.sh
```

`setup.sh` handles:
- Installing npm dependencies in `.channels/webhook-channel/` and `.tools/voice-tools/`
- Creating `config.env` from the template
- Scaffolding empty directories
- Checking for whisper.cpp and ffmpeg
- Printing next steps

Then:

```bash
# 1. Edit config.env with your Telegram chat ID
# 2. Set up Telegram (one-time — see below)
# 3. Install cron jobs for overnight dreams
# 4. Launch:
./start.sh
```

### Telegram Setup

Telegram integration requires a few one-time steps:

1. Create a bot via [@BotFather](https://t.me/BotFather) on Telegram
2. Inside a Claude Code session: `/plugin install telegram`
3. Then: `/telegram:access` to pair your bot
4. See the [official guide](https://docs.anthropic.com/en/docs/claude-code/telegram) for details

**Important — the dropped message fix:**

The default `plugin:` delivery path drops messages that arrive while Claude is mid-response (no queue, no retry — [#1143](https://github.com/anthropics/claude-plugins-official/issues/1143)). This repo works around it:

- Telegram is registered as an MCP server in `.mcp.json` (not as a channel plugin)
- `start.sh` uses `--dangerously-load-development-channels server:telegram` (not `plugin:telegram`)
- Each channel needs its own `--dangerously-load-development-channels` flag (comma-separated does NOT work)

This gives reliable message delivery — every message arrives, even during long operations.

### Multiple Instances

Clone into different directories. Each gets its own vault, memory, config, and webhook port:

```bash
git clone https://github.com/jason-c-dev/claude-second-brain.git work-brain && cd work-brain && ./setup.sh
git clone https://github.com/jason-c-dev/claude-second-brain.git research-brain && cd research-brain && ./setup.sh
```

Change `WEBHOOK_PORT` in each instance's `config.env` to avoid port conflicts. Each instance needs its own Telegram bot token.

## How It Works

### Wiki System

The wiki follows the [Karpathy LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern:

1. **Raw sources** land in `raw/` — articles, notes, conversation captures, web clips
2. **Claude compiles** them into curated wiki articles in `wiki/` — cross-linked, structured, with key takeaways
3. **CLAUDE.md** defines the schema — topic structure, naming conventions, article lifecycle, contradiction handling
4. **Every query** checks the wiki first, falls back to raw/, then improves the wiki so the next query doesn't have to
5. **The manifest** (`.config/compiled-raw.txt`) tracks which raw files have been compiled — prevents reprocessing

### Dream Cycles

Two overnight cron jobs trigger dream cycles:

- **2:03 AM — Memory dream** (`/dream-memory`): A subagent reviews Claude's session memories and consolidates them — merging duplicates, pruning stale entries, updating the index
- **3:33 AM — Wiki dream** (`/dream-wiki`): A subagent compiles any new raw sources into wiki articles

**How it works:**

```
cron (2:03 AM)
  → curl POST http://127.0.0.1:8790/dream-memory
    → webhook-channel receives HTTP request
      → pushes MCP notification into Claude session
        → Claude routes to /dream-memory skill
          → skill spawns subagent with fresh context
            → subagent consolidates memories
              → orchestrator logs to wiki/log.md
                → orchestrator sends report to Telegram
```

**Why subagents?** The orchestrator-subagent pattern avoids the self-evaluation trap — an agent reviewing its own memories in the same context that created them. Fresh context means honest evaluation. The subagent inherits CLAUDE.md conventions but has no session history to be biased by.

### Voice Transcription

When a Telegram voice message arrives:

1. Claude downloads the audio via the Telegram `download_attachment` tool
2. Calls the `voice_transcribe` MCP tool
3. voice-tools converts to WAV via ffmpeg, transcribes via whisper.cpp
4. Claude processes the text and replies on Telegram

Fully local — no audio leaves your machine.

### Telegram Gate Hook

CLAUDE.md can tell Claude to acknowledge messages, but instructions are probabilistic — 90% compliance isn't enough for user-visible behaviour. The Telegram gate hook (`.hooks/telegram_gate.py`) is deterministic:

1. A Telegram message arrives → gate closes
2. Claude tries to use any non-Telegram tool → **blocked** (exit code 2)
3. Claude sends a react (eyes emoji) + status reply → gate opens
4. Now Claude can proceed with the actual work

Circuit breaker: after 3 consecutive blocks, the gate forces open with a warning. Standard library Python only — no pip dependencies.

## Intake Workflows

Content enters `raw/` several ways:

| Method | How |
|--------|-----|
| **Obsidian Web Clipper** | Browser extension clips articles directly into `raw/`. One click from any tab. |
| **Manual drop** | Drag files into `raw/` |
| **Conversation capture** | During a Claude session, say "save this to raw" |
| **Telegram** | Send URLs or content to Claude, ask it to save to `raw/` |
| **Daily notes** | Configure Obsidian daily notes to save to `raw/` |

**Web Clipper setup:**
1. Install [Obsidian Web Clipper](https://obsidian.md/clipper) browser extension
2. Set vault to this directory
3. Set save folder to `raw/`
4. Configure the template to include frontmatter (title, source URL, date, tags)

## Obsidian Integration

Two modes:

### Repo IS the Vault (Default)

The simplest setup. Clone the repo, open it as an Obsidian vault. Everything works:

- `raw/`, `wiki/`, and `output/` appear in the vault
- Wiki `[[links]]` render as clickable graph connections
- All infrastructure (`.channels/`, `.tools/`, `.hooks/`, `.claude/`, `.config/`) is invisible — dot-directories are hidden by default in Obsidian
- No JS files, no `node_modules`, no config polluting your graph view

### Repo is Separate

If you already have a vault and want to keep the repo elsewhere:

1. Set `OBSIDIAN_VAULT` in `config.env` to your vault path
2. Set `OBSIDIAN_VAULT_NAME` to the name registered in Obsidian
3. Claude will read/write to the vault path instead of relative paths

**Optional dependencies:**
- `obsidian` CLI (`npm install -g obsidian-cli`) — enables search, daily notes, append operations from the terminal. Requires Obsidian to be running. Claude falls back to direct file writes if unavailable.

## Configuration Reference

| Variable | File | Default | Description |
|----------|------|---------|-------------|
| `TELEGRAM_CHAT_ID` | config.env | — | Your Telegram chat ID for dream reports |
| `WEBHOOK_PORT` | config.env | 8790 | Webhook HTTP server port |
| `STT_MODEL` | config.env | — | Path to whisper.cpp GGML model |
| `STT_PATH` | config.env | `whisper-cli` | Whisper binary name |
| `OBSIDIAN_VAULT` | config.env | (repo dir) | Obsidian vault path (if separate) |
| `OBSIDIAN_VAULT_NAME` | config.env | — | Vault name in Obsidian |
| Cron schedule | .config/crontab | 2:03/3:33 AM | Dream cycle times |
| Webhook host | .mcp.json env | 127.0.0.1 | Webhook bind address |

## The Biological Memory Model

The system mirrors how biological memory works:

| Biological | Digital |
|-----------|---------|
| Sensory input | `raw/` — articles, notes, clips |
| Active study | Compile workflow — reading, synthesizing, cross-linking |
| Long-term memory | `wiki/` — curated, structured, retrievable |
| REM sleep | Dream cycles — overnight consolidation |
| Retrieval practice | Wiki queries — each retrieval strengthens the encoding |
| Synaptic reinforcement | Query fallback loop — wiki miss → raw hit → wiki update |

This isn't a metaphor. It's the actual architecture.

## Troubleshooting

**Dreams not firing:**
1. Is Claude running? (`./start.sh` must be active)
2. Is the webhook listening? `curl http://127.0.0.1:8790/health`
3. Are cron jobs installed? `crontab -l | grep dream`

**Telegram messages dropping:**
- Make sure `start.sh` uses `server:telegram`, not `plugin:telegram`
- Check that `.mcp.json` has the telegram server entry
- Each `--dangerously-load-development-channels` flag must be separate

**Voice not transcribing:**
- Is `whisper-cli` installed? `which whisper-cli`
- Is `ffmpeg` installed? `which ffmpeg`
- Is `STT_MODEL` set in `.mcp.json` to a valid model path?

**Wiki not compiling:**
- Check `wiki/log.md` for recent activity
- Check `.config/compiled-raw.txt` — is the file already listed?
- Try manually: tell Claude "compile" in a session

**Manifest out of sync:**
- If articles exist in wiki/ but raw files keep being reprocessed, check `.config/compiled-raw.txt` for filename mismatches (watch for Unicode apostrophes vs ASCII)

## Background

This project was built as part of a blog series on autonomous AI agents:

- Part 1: Building the wiki system and dream cycles
- Part 2: Nightmare scenarios, subagent architecture, and the biological memory model

The codebase draws from:
- [claude-channels](https://github.com/jason-c-dev/claude-channels) — webhook-channel, voice-tools, and Telegram gate
- [Karpathy's LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the wiki pattern
- Anthropic's Auto Dream system — the memory consolidation model

## License

[MIT](LICENSE)
