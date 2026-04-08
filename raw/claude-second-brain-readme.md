---
title: "Claude Second Brain — Project README"
source: "https://github.com/jason-c-dev/claude-second-brain"
created: 2026-04-08
description: "The README for this repo. A meta-example: when the wiki dream runs for the first time, it compiles this file into the wiki — the system documents itself."
tags:
  - "meta"
  - "getting-started"
---

## Source: Repository README, self-referential

This is the sample raw file included with claude-second-brain. It demonstrates the intake format and serves as a meta-example: when you run your first wiki compilation (either manually via "compile" or overnight via the dream cycle), Claude will process this file and create a wiki article about the system itself.

### What This Demonstrates

- **Raw file format**: YAML frontmatter with title, source, date, description, and tags
- **Immutability**: once filed in raw/, this source is never modified — Claude reads it but writes to wiki/
- **Compile workflow**: this file goes through triage (wiki-worthy? yes), topic assignment, article creation, manifest tracking
- **The manifest**: after compilation, the filename is appended to `.config/compiled-raw.txt` so it's never reprocessed

### Key Concepts

- **raw/** is the inbox — sources land here via manual drop, conversation capture, Obsidian Web Clipper, or Telegram
- **wiki/** is the curated knowledge base — Claude as librarian writes and maintains articles
- **Dreams** run overnight — memory consolidation at 2:03 AM, wiki compilation at 3:33 AM
- **CLAUDE.md** is the schema — it defines how Claude behaves as librarian, what qualifies for wiki inclusion, and how to handle contradictions
- **Subagents** get fresh context — the dream orchestrator spawns a subagent so the compilation doesn't pollute the main session

### Architecture

The system follows the Karpathy LLM Wiki pattern:
1. Raw sources accumulate (input)
2. An LLM librarian curates them into a structured wiki (processing)
3. CLAUDE.md defines the schema and conventions (rules)
4. The wiki becomes the first place to look for answers (retrieval)
5. Each query that hits raw/ improves the wiki (reinforcement)

Combined with overnight dream cycles inspired by Anthropic's Auto Dream system, this creates a biological memory model: raw/ is sensory input, wiki/ is long-term memory, dreams are REM sleep, and queries are synaptic reinforcement.
