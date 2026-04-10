---
name: wiki-intake
description: "Wiki intake and compilation — process new content into the knowledge base. Use when the user says 'compile', 'add this to the wiki', 'process raw files', drops content in raw/, shares a URL to capture, or wants to ingest new material into the wiki. Also use when new raw files need processing or the user mentions intake, ingestion, or web clipping."
---

## Wiki Intake and Compilation

Process new content into the wiki knowledge base. Content enters raw/, gets compiled into curated wiki articles.

### Intake Pathways

Content enters raw/ four ways:
1. **Daily notes** — Obsidian daily notes save directly to raw/ (configure daily notes plugin to save to raw/). These accumulate tasks, thoughts, and observations throughout the day and are subject to compilation like any other raw file.
2. **Manual drop** — user puts files in raw/ directly
3. **Conversation capture** — when wiki-worthy knowledge surfaces, ask: "This seems worth capturing — want me to add it to raw/?" Only create the note on approval. Include `## Source: conversation, YYYY-MM-DD` at the top.
4. **URL/content ingestion** — user shares a URL or content block; extract the useful parts and save to raw/

### Compile Workflow

When compiling raw sources into wiki articles:
1. Read `.config/compiled-raw.txt` to see which raw files are already compiled
2. Read each uncompiled raw file
3. Decide which topic it belongs to (or create a new topic folder)
4. Write a wiki article with key takeaways and [[wiki links]] to related concepts
5. Update that topic's _index.md
6. Update wiki/_master-index.md
7. If a raw file spans multiple topics, create articles in both and cross-link
8. Append an entry to wiki/log.md
9. Append each compiled raw filename to `.config/compiled-raw.txt`

### Log Format

`wiki/log.md` is a chronological, append-only record of wiki activity. Format each entry as:

```
## [YYYY-MM-DD] action | Description
Brief notes on what changed or was added.
```

Where `action` is one of: `ingest`, `query`, `lint`, `update`. The LLM appends to this file; the user reads it to see what's evolved.
