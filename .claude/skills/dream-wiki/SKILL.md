---
name: dream-wiki
description: "Wiki compilation — spawns a subagent with fresh context to compile raw/ sources into wiki articles. Reports result to Telegram."
argument-hint: ""
---

Spawn a subagent to perform wiki compilation. The subagent gets fresh context (no session bleed) but inherits CLAUDE.md conventions.

1. Use the Agent tool to launch a subagent with the prompt below
2. When the subagent returns its summary, append a log entry to `wiki/log.md`:
   ```
   ## [YYYY-MM-DD] dream-wiki | Overnight wiki compilation
   Brief notes on what was compiled.
   ```
3. Send the summary to Telegram (chat_id: YOUR_CHAT_ID — set TELEGRAM_CHAT_ID in config.env)
4. If nothing changed, send: "Wiki Dream: no new raw files to compile."

## Subagent Prompt

```
You are performing a wiki dream — an overnight compilation pass that processes raw sources into the wiki knowledge base. Follow the conventions in CLAUDE.md for all wiki operations.

## Paths

- Raw sources: raw/
- Wiki: wiki/
- Master index: wiki/_master-index.md
- Activity log: wiki/log.md

## Phase 1 — Inventory

1. List all files in raw/
2. Read .config/compiled-raw.txt to get the set of already-compiled filenames (one per line)
3. Read wiki/_master-index.md to understand the current topic structure
4. Build a list of uncompiled raw files (those not in the manifest)
5. After compiling, append each newly compiled filename to .config/compiled-raw.txt

Short-circuit: If no uncompiled raw files exist, return "No new raw files to compile."

## Phase 2 — Triage

For each uncompiled raw file, read it and classify:
- Wiki-worthy: contains knowledge worth preserving (decisions, research, evaluations, tools, processes, people, project documentation)
- Daily note only: contains only tasks/personal items (files matching YYYY-MM-DD.md with only checkbox items) — skip
- Already covered: content substantially duplicates existing wiki articles — skip

## Phase 3 — Compile

For each wiki-worthy raw file, follow the standard compile workflow:
1. Read the raw file fully
2. Decide which topic it belongs to (check existing topics first, or create a new topic folder)
3. Write a wiki article with:
   - Key Takeaways section
   - [[wiki links]] to related concepts
   - Bullet points over paragraphs
   - Lowercase-hyphen filenames
4. Update that topic's _index.md
5. Update wiki/_master-index.md
6. If a raw file spans multiple topics, create articles in both and cross-link

## Phase 4 — Cross-Link Audit

After all new articles are written:
1. Scan new articles for concepts that connect to existing wiki articles
2. Add [[wiki links]] where relevant — both directions
3. Verify all new articles appear in their topic's _index.md

## Phase 5 — Return Summary

Return a brief summary. Format:
"Wiki Dream complete. Compiled N new articles from M raw files. New topics: [list]. Updated topics: [list]. Skipped K files (daily notes / already covered)."
If nothing new: "No new raw files to compile."

Do NOT send Telegram messages or update wiki/log.md — the orchestrator handles reporting.
```
