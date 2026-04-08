---
name: dream-memory
description: "Memory consolidation — spawns a subagent with fresh context to review and consolidate session memories. Reports result to Telegram."
argument-hint: ""
---

Spawn a subagent to perform memory consolidation. The subagent gets fresh context (no session bleed) but inherits CLAUDE.md conventions.

1. Use the Agent tool to launch a subagent with the prompt below
2. When the subagent returns its summary, append a log entry to `wiki/log.md`:
   ```
   ## [YYYY-MM-DD] dream-memory | Memory consolidation summary
   Brief notes on what changed.
   ```
3. Send the summary to Telegram (chat_id: YOUR_CHAT_ID — set TELEGRAM_CHAT_ID in config.env)
4. If nothing changed, send: "Memory Dream: memories are already tight, nothing to consolidate."

## Subagent Prompt

```
You are performing a memory dream — a reflective pass over Claude's memory files. Synthesize what was learned recently into durable, well-organized memories so that future sessions can orient quickly.

## Paths

- Memory directory: the auto memory directory for this project (Claude Code auto-detects this — check ~/.claude/projects/ for the memory/ subfolder matching this project path)
- Session transcripts: the project directory under ~/.claude/projects/ (large JSONL files — grep narrowly, don't read whole files)

## Memory File Format

Each memory file uses YAML frontmatter:

---
name: {{memory name}}
description: {{one-line description}}
type: {{user, feedback, project, reference}}
---

{{memory content}}

Types:
- user — role, preferences, knowledge
- feedback — corrections and confirmed approaches (include Why: and How to apply: lines)
- project — ongoing work, goals, decisions (include Why: and How to apply: lines)
- reference — pointers to external systems

## Phase 1 — Orient

- ls the memory directory to see what already exists
- Read MEMORY.md to understand the current index
- Skim existing topic files so you improve them rather than creating duplicates

## Phase 2 — Gather Recent Signal

Look for new information worth persisting. Sources in rough priority order:

1. Existing memories that drifted — facts that contradict something in the codebase now
2. Transcript search — grep the JSONL transcripts for narrow terms only. Don't exhaustively read transcripts.

Focus on: user corrections, confirmed approaches, explicit save requests, recurring themes, important decisions.

Short-circuit: If no JSONL files are newer than the most recent memory file modification, return "Nothing new to consolidate — memories are already tight."

## Phase 3 — Consolidate

For each thing worth remembering, write or update a memory file. Focus on:
- Merging new signal into existing topic files rather than creating near-duplicates
- Converting relative dates to absolute dates
- Deleting contradicted facts at the source
- Removing stale memories

## Phase 4 — Prune and Index

Update MEMORY.md so it stays under 200 lines. It's an index, not a dump.
- Remove stale/wrong/superseded pointers
- Add pointers to newly important memories
- Resolve contradictions

## Phase 5 — Return Summary

Return a brief summary of what you consolidated, updated, or pruned. Format:
"Memory Dream complete. [N files updated, M created, K pruned]. Key changes: ..."
If nothing changed: "Nothing new to consolidate — memories are already tight."

Do NOT send Telegram messages or update wiki/log.md — the orchestrator handles reporting.
```
