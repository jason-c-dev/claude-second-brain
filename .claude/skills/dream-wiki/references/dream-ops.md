# Dream Cycles — Operations Reference

## Schedule

- **2:03 AM** — Memory dream (`/dream-memory`): consolidates Claude's per-session memory files
- **3:33 AM** — Wiki dream (`/dream-wiki`): compiles unprocessed raw/ sources into wiki articles

Adjust times in `.config/crontab` to suit your schedule.

## Telegram Reporting

Both dreams send a summary to Telegram on completion (configure TELEGRAM_CHAT_ID in config.env).
If nothing changed, send a brief "nothing to consolidate/compile" message.
Log all dream activity to wiki/log.md.

## Re-scheduling

If dreams stop firing, verify:
1. Claude Code session is running with `--dangerously-load-development-channels server:telegram --dangerously-load-development-channels server:webhook-channel`
2. Webhook-channel is listening: `curl http://127.0.0.1:8790/health`
3. Crontab entries exist: `crontab -l | grep dream`

## Troubleshooting

- **Webhook port mismatch** — the port lives in `.mcp.json` (source of truth). If changed, update `.mcp.json` and re-install cron jobs.
- **Manifest out of sync** — if raw files keep being reprocessed, check `.config/compiled-raw.txt` for filename mismatches (watch for Unicode apostrophes vs ASCII).
- **Multiple bun instances** — if Telegram messages are dropping during dreams, check `ps aux | grep bun | grep telegram` for competing consumers.
