---
name: task-tracker
description: "Track tasks and todos in the vault. Use when the user says 'add this to my todo', 'add this as a task', 'put this on my list', 'put this on the backlog', 'let's circle back to this later', 'don't let me forget', 'note for later', 'park this', 'we should come back to this', 'remind me to X', 'I need to do X later', or any phrase that implies queuing an action for future pickup. Also fires when the user wants to see pending tasks, check progress on multi-day work, or mark tasks complete. IMPORTANT: Do NOT fire on 'remember this', 'remember that X is Y', 'save this fact', 'store this about me' — those are memory actions, not task actions (see Task vs Memory Disambiguation below)."
---

## Task Tracker

Capture, organize, and track tasks in the vault using Obsidian-native `- [ ]` checkbox syntax.

### Task Storage

Two locations, chosen by timescale:

| Location | For | Example |
|----------|-----|---------|
| `raw/YYYY-MM-DD.md` (today's daily note) | Ephemeral, today-specific, quick action items | "Check emails", "Call someone back", "Test the voice flow" |
| `wiki/tasks.md` | Persistent, multi-day, architectural, cross-session | "CSB v2 skill-based rewrite", "Blog: Who guards the guards?", "Install yt-dlp" |

Default to the daily note for ambiguous cases. Promote to `wiki/tasks.md` if it's clearly multi-day, architectural, or spans future work.

### Format

- Use `- [ ]` for open tasks, `- [x]` when complete
- Include a brief context line where useful — one line, not a paragraph
- Tag with `#` keywords if helpful for filtering (e.g., `#blog`, `#infra`, `#csb-v2`)

### Task vs Memory Disambiguation

The trigger phrases are similar but the intent differs:

| User says | Action | Why |
|-----------|--------|-----|
| "Remind me to follow up tomorrow" | Task → daily note | It's an action to take later |
| "Don't let me forget to circle back on this video" | Task → `wiki/tasks.md` | Future action |
| "Circle back on this later" | Task → `wiki/tasks.md` | Queuing a revisit |
| "Remember my birthday is [date]" | Memory → `user_profile.md` | Factual info about the user |
| "Remember I prefer American spelling" | Memory → `feedback_*.md` | Behavioral preference |
| "Remember we tried X and it failed" | Memory or project log | Historical context |

**Verbs matter.** "Remind me to X", "Circle back on X", "Don't let me forget X" = tasks. "Remember that X is Y", "Save this about me" = memory.

**When ambiguous, ASK.** Example: "Hey, you asked me to remember X — should I add that to your task list, or save it as a memory about you? Tasks are actions to take later; memory is durable facts."

Don't silently route to the wrong place. A 15-word clarifying question is better than a misplaced entry.

### Workflow

When the user triggers a task action:

1. Classify timescale — today vs multi-day (default to daily note if unsure)
2. Classify intent — task vs memory (ask if unsure)
3. For today → append `- [ ]` to `raw/YYYY-MM-DD.md` (create if not exists)
4. For multi-day → append `- [ ]` to appropriate section in `wiki/tasks.md` (create section if needed)
5. Acknowledge briefly: "Added to today" or "Queued in tasks.md under [section]"

### When Showing Tasks

If the user asks "what's on my list", "what's pending", "what tasks do I have":
1. Read today's daily note
2. Read `wiki/tasks.md`
3. Surface open items (`- [ ]`) grouped by location
4. Don't surface completed items unless asked

### When Marking Tasks Complete

When the user says "I did X", "X is done", "mark X complete":
1. Find the matching `- [ ]` line in daily note or tasks.md
2. Change to `- [x]`
3. Add a brief note if it produced a wiki article, blog, or other artifact

### Daily Note Conventions

- File name: `raw/YYYY-MM-DD.md` (ISO date, today)
- Minimal structure — just the task list, no required heading
- Create lazily (first task of the day triggers creation)
- Completed tasks stay in the daily note as a historical record
- Daily notes are picked up by wiki intake but only if they contain wiki-worthy content beyond tasks

### tasks.md Conventions

- Location: `wiki/tasks.md`
- Structure: grouped by theme with `## Section Headings`
- Typical sections: Infrastructure, Refactoring, Research / Architecture, Content / Blog, Parity / Maintenance
- Each item: `- [ ] brief description — optional context or link to related wiki article`
- When a task spawns a wiki article, link it inline
- Completed items: archive to a `## Done` section at the bottom with completion date, or delete if trivial

### Examples

**User:** "Let's circle back to refactoring the audit skill later"
**Action:** Add to `wiki/tasks.md` under Refactoring: `- [ ] Refactor audit skill`
**Response:** "Queued in tasks.md under Refactoring."

**User:** "Remind me to check a deadline before next month"
**Action:** Add to `wiki/tasks.md` under an appropriate section with the date.
**Response:** "Queued in tasks.md with the deadline noted."

**User:** "Remember my birthday is [date]"
**Action:** This is memory, not a task. Update `user_profile.md` with the fact.
**Response:** "That's memory rather than a task — saved to your personal profile."

**User (ambiguous):** "Don't let me forget about that contract change"
**Action:** ASK.
**Response:** "Want me to track that as an action to revisit (task), or as durable context (memory)? Could be either."
