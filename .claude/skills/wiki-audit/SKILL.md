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

### Scoring Rubric

After completing the checklist, calculate a structural quality score out of 100. Deduct points per issue found:

| Category | Max Points | Deductions |
|----------|-----------|------------|
| Index integrity | 20 | -5 per missing index entry, -10 per orphan article |
| Cross-links | 20 | -2 per missing bidirectional link, -5 per isolated article |
| Consistency | 20 | -10 per contradiction, -5 per inconsistent fact |
| Coverage | 15 | -3 per coverage gap, -5 per topic mentioned but uncovered |
| Staleness | 10 | -3 per stale article, -5 per outdated fact still presented as current |
| Formatting | 15 | -2 per missing Key Takeaways, -2 per non-standard filename, -1 per missing frontmatter |

Report the score as: `Score: XX/100` with a breakdown by category. Track scores over time in the log to show improvement trends.

### Rules

- Suggest improvements, but don't make changes without confirmation
- Present both perspectives when information conflicts, with dates and sources
- Ask the user if unsure which version to trust

### Log Format

Append a lint entry to wiki/log.md:

```
## [YYYY-MM-DD] lint | Wiki audit — Score: XX/100
Category breakdown: Index XX/20, Cross-links XX/20, Consistency XX/20, Coverage XX/15, Staleness XX/10, Formatting XX/15.
Brief notes on findings and recommendations.
```
