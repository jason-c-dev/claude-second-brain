# Knowledge Base — Vault Conventions

This project is an Obsidian vault. Use Obsidian-flavoured markdown for all files — `[[wikilinks]]`, properties, callouts, and embeds. Load the `obsidian-markdown` skill if available.

## Vault Structure
- /raw — inbox for source material, conversation captures, and clipped articles (input zone; sources are immutable once filed — Claude reads but never modifies them)
- /wiki — curated knowledge base, maintained by Claude as librarian (see Wiki System)
- /output — ephemeral exports, one-off reports, and transient query results (snapshots, not living docs; name as `YYYY-MM-DD-description.md`). If a query answer has lasting reference value, file it as a wiki article instead.

## Wiki System
You are the librarian of the wiki/ folder — the user's curated second brain. You write and maintain everything in it. Consult it when answering questions. Suggest additions when you notice knowledge worth preserving.

### What Goes Where
- **Claude memory** (`~/.claude/.../memory/`): user preferences, working habits, feedback, session context — helps Claude work with the user
- **Wiki** (`wiki/`): curated knowledge about topics, people, tools, decisions, research — the user's long-term reference
- Rule of thumb: if the user would want to find this six months from now → wiki. If it only helps Claude work better → memory.

### Structure
- wiki/_master-index.md is the entry point — lists every topic with a one-line description.
- Each topic gets its own subfolder with its own _index.md listing all articles.

### Topic Guidance
- Topics emerge organically from content — no pre-defined taxonomy
- Name for the subject, not the source (e.g., `obsidian-plugins/` not `march-research/`)
- Sweet spot: 3–10 articles per topic. Fewer → fold into a broader topic. More → consider splitting.
- Every topic folder gets `_index.md` with a one-paragraph description, source list, and article list
- People, organizations, and tools can get their own pages within a topic — not everything needs to be a summary or overview

### Intake
Content enters raw/ four ways:
1. **Daily notes** — Obsidian daily notes save directly to raw/ (configure daily notes plugin to save to raw/). These accumulate tasks, thoughts, and observations throughout the day and are subject to compilation like any other raw file.
2. **Manual drop** — user puts files in raw/ directly
3. **Conversation capture** — when wiki-worthy knowledge surfaces, ask: "This seems worth capturing — want me to add it to raw/?" Only create the note on approval. Include `## Source: conversation, YYYY-MM-DD` at the top.
4. **URL/content ingestion** — user shares a URL or content block; extract the useful parts and save to raw/

After intake, follow the normal compile workflow.

### Compiling
When I say "compile" or dump new material in raw/:
1. Read `.config/compiled-raw.txt` to see which raw files are already compiled
2. Read each uncompiled raw file
3. Decide which topic it belongs to (or create a new topic folder)
4. Write a wiki article with key takeaways and [[wiki links]] to related concepts
5. Update that topic's _index.md
6. Update wiki/_master-index.md
7. If a raw file spans multiple topics, create articles in both and cross-link
8. Append an entry to wiki/log.md
9. Append each compiled raw filename to `.config/compiled-raw.txt`

### Querying
For **every** question — not just explicit wiki queries — consult the wiki first:
1. Use `obsidian vault="Vault" search query="<terms>"` as the first pass — this uses Obsidian's built-in search index which understands wikilinks, tags, and frontmatter
2. Read wiki/_master-index.md to check for relevant topics
3. If a topic exists, read that topic's _index.md to find relevant articles
4. Read the specific articles
5. Use `obsidian vault="Vault" backlinks file="<name>"` to discover related articles through the link graph
6. Synthesize the answer
7. If the wiki answer is incomplete, check raw/ for source material that may contain more detail (wiki articles link back to their sources)
8. Mention when drawing on wiki knowledge: "Based on what's in the wiki..."
9. If the answer has lasting reference value, file it as a wiki article — comparisons, analyses, and novel connections should compound into the wiki, not vanish into chat history. If raw/ filled a gap the wiki missed, update the wiki article so the gap is closed for next time.
10. Log significant queries to wiki/log.md

This is non-optional. The wiki is always the first place to look. Raw/ is the fallback. Each query that hits raw/ should improve the wiki so the next query doesn't have to. Prefer `obsidian search` over Grep for wiki queries — Grep is for precise text matching, Obsidian search is for finding relevant content.

### Auditing
When I say "audit" or "lint", review the wiki for:
- Inconsistent or contradictory information
- Missing cross-links between related concepts
- Gaps in coverage
- Suggest improvements, but don't make changes without confirmation
- Log the lint pass to wiki/log.md

### Log
`wiki/log.md` is a chronological, append-only record of wiki activity — ingests, significant queries, lint passes, and major updates. Format each entry as:

```
## [YYYY-MM-DD] action | Description
Brief notes on what changed or was added.
```

Where `action` is one of: `ingest`, `query`, `lint`, `update`. This gives cross-session context since the vault has no git history. The LLM appends to this file; the user reads it to see what's evolved.

## Article Lifecycle

### Updating Existing Articles
When new information arrives about an existing topic:
1. Check if an existing article covers it
2. If yes: update the article in place, add a `## Revision History` note for substantial changes (`- YYYY-MM-DD: Updated with [brief description]`)
3. Update the topic _index.md if the article's scope changed
4. If no existing article covers it: create a new one and cross-link

### Handling Contradictions
- Don't silently overwrite. Flag the contradiction.
- If the new info is clearly more current/authoritative: update the article, note what changed
- If ambiguous: present both perspectives with dates and sources
- Ask the user if unsure which to trust

### Staleness
- Note potentially stale articles during audits
- No automatic expiration — knowledge doesn't expire on a schedule

## Proactive Librarian Behavior

### When to Suggest Wiki Additions
- During conversations, if you notice wiki-worthy knowledge, mention it briefly at a natural pause point
- Always ask before creating notes — never auto-capture
- If the user declines or ignores, move on. Don't ask again about the same thing.

### What Qualifies as Wiki-Worthy
- Decisions and their rationale
- Tool or technology evaluations
- Notable contacts, people, or entities
- Research findings or synthesized insights
- Processes or workflows the user has refined
- Project architecture or design decisions

### What Does NOT Qualify
- Casual conversation or opinions in passing
- Temporary debugging context (that's Claude memory territory)
- Raw data without synthesis

## Conventions
- Always use [[wiki links]] when referencing other notes
- File names: lowercase with hyphens (e.g., ai-agent-overview.md)
- Keep articles concise — bullet points over paragraphs
- Always include a ## Key Takeaways section in wiki articles

## Telegram Communication

These rules apply when a message arrives via Telegram (tagged with `source="telegram"`), NOT when the user types directly into the CLI.

### Acknowledge First
When a Telegram message arrives, BEFORE any other tool call:
1. React with 👀
2. Send a brief status message (e.g. "Working on it...")

Only then proceed with the actual work. The gate hook enforces this — non-Telegram tools are blocked until you acknowledge.

### Progress Updates
- Edit your status message every 2-3 tool calls with specific progress
- Bad: "Processing..." Good: "Found 14 new emails, reading the important ones..."
- When done, send a NEW reply with the final result — edits don't trigger push notifications

### Voice Messages
1. React 👀 and send "Transcribing voice message..."
2. Download the attachment (`download_attachment` with the `file_id`)
3. Transcribe (`voice_transcribe` with the downloaded file path)
4. Process the transcribed text as if it were typed
5. Reply with your response. If transcription fails, ask the user to type it instead.

### Formatting
- Keep replies concise and readable
- Use plain text unless the user asks for formatted output
- Break long responses into chunks rather than walls of text

## Dream Cycles

Overnight consolidation triggered via webhook-channel. Two cron jobs fire webhooks that Claude routes to skills.

### Webhook Routing
- `/dream-memory` → run the `/dream-memory` skill (memory consolidation)
- `/dream-wiki` → run the `/dream-wiki` skill (wiki compilation)

### Schedule
- **2:03 AM** — Memory dream (consolidates Claude's per-session memory files)
- **3:33 AM** — Wiki dream (compiles unprocessed raw/ sources into wiki articles)

Adjust times in `.config/crontab` to suit your schedule.

### Telegram Reporting
Both dreams send a summary to Telegram on completion (configure TELEGRAM_CHAT_ID in config.env).
If nothing changed, send a brief "nothing to consolidate/compile" message.
Log all dream activity to wiki/log.md.

### Re-scheduling
If dreams stop firing, verify:
1. Claude Code session is running with `--dangerously-load-development-channels server:telegram --dangerously-load-development-channels server:webhook-channel`
2. Webhook-channel is listening: `curl http://127.0.0.1:8790/health`
3. Crontab entries exist: `crontab -l | grep dream`

## Obsidian Integration

This repo is designed to be opened directly as an Obsidian vault. All infrastructure lives in dot-directories (`.channels/`, `.tools/`, `.hooks/`, `.claude/`, `.config/`) so Obsidian ignores them — only knowledge content appears in the graph view.
