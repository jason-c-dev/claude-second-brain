---
name: wiki-audit
description: "Wiki audit and lint — review the wiki for quality, consistency, and completeness. Use when the user says 'audit', 'lint', 'review the wiki', 'check for issues', 'check wiki health', or wants to assess the knowledge base quality. Also handles staleness checks and cross-link verification."
---

## Wiki Audit

Review the wiki for quality, consistency, and completeness. Log results to wiki/log.md.

### Audit Checklist

1. **Consistency** — check for contradictory information across articles
2. **Cross-links** — find missing [[wiki links]] between related concepts (both directions)
3. **Coverage gaps** — identify topics mentioned but not covered
4. **Index integrity** — verify all articles appear in their topic's _index.md and in wiki/_master-index.md
5. **Orphan detection** — find articles not linked from any index
6. **Staleness** — flag articles that may be outdated (note potentially stale articles, but no automatic expiration — knowledge doesn't expire on a schedule)

### Rules

- Suggest improvements, but don't make changes without confirmation
- Present both perspectives when information conflicts, with dates and sources
- Ask the user if unsure which version to trust

### Log Format

Append a lint entry to wiki/log.md:

```
## [YYYY-MM-DD] lint | Description
Brief notes on findings and recommendations.
```
