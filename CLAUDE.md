# Knowledge Base — Vault Conventions

This project is an Obsidian vault. Use Obsidian-flavoured markdown for all files — `[[wikilinks]]`, properties, callouts, and embeds. Before writing or editing any `.md` file, invoke the `obsidian:obsidian-markdown` skill via the Skill tool to load its conventions. Don't wing it from memory — check the skill.

## Vault Structure
- /raw — inbox for source material, conversation captures, and clipped articles (immutable once filed — read but never modify)
- /wiki — curated knowledge base, maintained by Claude as librarian (see Wiki System)
- /output — ephemeral exports and transient query results (name as `YYYY-MM-DD-description.md`). If a query answer has lasting reference value, file it as a wiki article instead.

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
- People, organizations, and tools can get their own pages within a topic

### Intake and Compilation
Use the `/wiki-intake` skill for adding content to raw/ and compiling into wiki articles.

### Querying
For **every** question — not just explicit wiki queries — consult the wiki first:
1. Use `obsidian vault="Vault" search query="<terms>"` as the first pass — this uses Obsidian's built-in search index which understands wikilinks, tags, and frontmatter
2. Read wiki/_master-index.md to check for relevant topics
3. If a topic exists, read that topic's _index.md to find relevant articles
4. Read the specific articles
5. Use `obsidian vault="Vault" backlinks file="<name>"` to discover related articles through the link graph
6. Synthesize the answer
7. If the wiki answer is incomplete, check raw/ for source material that may contain more detail
8. Mention when drawing on wiki knowledge: "Based on what's in the wiki..."
9. If the answer has lasting reference value, file it as a wiki article. If raw/ filled a gap the wiki missed, update the wiki article so the gap is closed for next time.
10. Log significant queries to wiki/log.md

This is non-optional. The wiki is always the first place to look. Prefer `obsidian search` over Grep for wiki queries.

### Auditing
Use the `/wiki-audit` skill for wiki quality reviews, lint passes, and staleness checks.

## Article Lifecycle

When new information arrives about an existing topic:
- Check if an existing article covers it. If yes: update in place, add a `## Revision History` note for substantial changes
- If no existing article covers it: create a new one and cross-link
- Don't silently overwrite contradictions — flag them. If the new info is clearly more authoritative, update and note what changed. If ambiguous, present both perspectives with dates and sources. Ask the user if unsure.
- Note potentially stale articles during audits — no automatic expiration

## Proactive Librarian

- Suggest wiki-worthy knowledge at natural pause points. Always ask before creating notes — never auto-capture. If declined, move on.
- Wiki-worthy: decisions and rationale, tool evaluations, notable contacts, research findings, refined processes, architecture decisions
- Not wiki-worthy: casual opinions, temporary debugging context (that's Claude memory), raw data without synthesis

## Conventions
- Always use [[wiki links]] when referencing other notes
- File names: lowercase with hyphens (e.g., ai-agent-overview.md)
- Keep articles concise — bullet points over paragraphs
- Always include a ## Key Takeaways section in wiki articles

## Telegram Communication
Use the `/telegram-protocol` skill for Telegram message handling (acknowledge-first, progress updates, voice messages, formatting). The gate hook (`.hooks/telegram_gate.py`) enforces acknowledgment mechanically — the skill provides the behavioral guidance.

## Dream Cycles

Overnight consolidation triggered via webhook-channel. Two cron jobs fire webhooks that Claude routes to skills.

### Webhook Routing
- `/dream-memory` → run the `/dream-memory` skill (memory consolidation)
- `/dream-wiki` → run the `/dream-wiki` skill (wiki compilation)

Both dreams send a summary to Telegram on completion. If nothing changed, send a brief "nothing to consolidate/compile" message. Log all dream activity to wiki/log.md. For schedule, troubleshooting, and re-scheduling, see `.claude/skills/dream-wiki/references/dream-ops.md`.

## Obsidian Integration

This repo is designed to be opened directly as an Obsidian vault. All infrastructure lives in dot-directories (`.channels/`, `.tools/`, `.hooks/`, `.claude/`, `.config/`) so Obsidian ignores them — only knowledge content appears in the graph view.
