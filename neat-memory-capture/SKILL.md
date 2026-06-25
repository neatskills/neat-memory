---
name: neat-memory-capture
description: Use after solving problems, making decisions, or discovering
  patterns - captures experience as markdown memories for cross-session recall
---

# Memory Capture

Capture reusable experience as structured memories.

## When to Use

After significant work:

- Solved non-trivial problem (3+ messages)
- Discovered effective approach/pattern
- Made architectural/tool choice
- Learned what NOT to do
- Developed preference/workflow

**Skip:** Trivial fixes, well-documented info, one-time issues,
temporary notes

## Memory Types

| Type | Location | Purpose | Soft Limit |
| -------------- | -------- | ---------------------- | ---------- |
| **Preference** | Global | Personal style/workflow | 200 |
| **Pattern** | Global | Universal principle | 200 |
| **Solution** | Project | What works here | 150 |
| **Lesson** | Project | What doesn't work | 150 |

Global = `~/.claude/neat_memory/`; Project = `{project}/.claude/neat_memory/`

**Format:** Markdown with YAML frontmatter (same as auto-memory)

**Filename:** `{slug}.md` (e.g., `sql-before-cache.md`)

**Soft Limits:** Non-blocking recommendations. User can save anyway, raise limit, or cleanup.

*See [../shared/file-operations.md](../shared/file-operations.md) for atomic writes and [references/memory-schema.md](references/memory-schema.md) for complete schema.*

## Process

### Step 1: Analyze Conversation

Scan backward to boundary (topic change, focus shift, previous
capture). Min 10, Max 100, Typical 20-50. Identify activity,
learning, reusability.

### Step 2: Detect Memory Type

```text
Detected capture-worthy content from last [N] messages.
1. Preference (global) 2. Pattern (global) 3. Solution (project)
4. Lesson (project) 5. Skip
Choose [1-5]: _
```

**If unsure:** Ask "Project-specific or universal?"

### Step 3: Extract Content

**Title:** 3-7 words
**Description:** Trigger-focused summary (see below)
**Content:** 200-500 words with **Why:** and **How to apply:** sections
**Tags:** 3-7 keywords (YAML array format)
**Triggers:** 3-5 search terms (YAML array format)
**Context:** Why/when discovered (goes in markdown body)

**Description Format (CRITICAL for auto-memory promotion):**

The description field determines when auto-memory loads this memory. Use trigger-focused phrasing:

✅ **Strong (trigger-focused):**
- "When writing SKILL.md files - extract code to scripts/, use JSON with inline comments, real roles for Role: field"
- "When facing API latency - optimize SQL queries before adding caching, not the other way around"
- "During code review - check for N+1 queries in ORM code before approving"
- "While debugging performance - profile first, then optimize hot paths, avoid premature optimization"

❌ **Weak (topic-only):**
- "Best practices for documenting AI-agent-driven skills"
- "SQL optimization before caching"
- "Code review guidelines"
- "Performance debugging approach"

**Pattern:** `When/During/While [context/trigger] - [key rule/principle]`

**Length:** Aim for 80-150 characters - specific enough to trigger correctly, concise enough for quick scanning.

Generate markdown with YAML frontmatter (see [references/memory-schema.md](references/memory-schema.md))

### Step 4: Generate Preview

```text
━━━ Memory Preview ━━━

Title: SQL Optimization Before Caching
Type: pattern
Tags: [performance, database, optimization]
Triggers: [performance, slow, latency]
Location: ~/.claude/neat_memory/patterns/sql-before-cache.md

Content preview:
When facing API latency, always optimize database queries...

**Why:** Caching masks symptoms; query optimization fixes root causes...

[y] Save  [e] Edit  [c] Change type  [n] Cancel: _
```

### Step 5: Handle Feedback

**[y]:** Save | **[e]:** Edit fields → preview → Step 4 |
**[c]:** Return to Step 2 | **[n]:** Cancel

### Step 5.5: Check Filename Collision

**Generate slug from title and check for collision:**

```text
Checking for existing memory with same name...
```

**If filename exists (e.g., `sql-before-cache.md`):**

1. Load existing memory from file
2. Calculate overlap (reuse `shared/duplicate-detection.md` logic)
3. If overlap >= 0.75 (75% similar): Show duplicate UI
4. Else: Check conflict (reuse `shared/conflict-detection.md` logic)
5. If conflict: Show conflict UI
6. Else: Show collision UI (same name, different content)

**Duplicate UI:**

```text
━━━ Duplicates Detected ━━━

[1] sql-before-cache.md - SQL Before Cache (existing)
    Created: 2026-06-20
    Content: "When facing API latency..."
    
[2] sql-optimization-before-caching - SQL Optimization Before Caching (new)
    Content: "Always optimize database queries..."

These overlap significantly (85% similar).

What should I do?
  [b] Use both (rename new)  [m] Merge  [1] Use existing  [2] Replace with new  [k] Keep separate
  
Choose: _
```

**Handle choices:**

- `[b]`: Keep existing, ask for alternate title for new → regenerate slug → retry save
- `[m]`: Merge using existing algorithm, update existing file
- `[1]`: Cancel save, keep existing
- `[2]`: Delete existing, save new (replace)
- `[k]`: Ask for alternate title → regenerate slug → retry save

**Conflict UI:** (Use `shared/conflict-detection.md` UI)

**Collision UI:** (rare - same slug, but not duplicate/conflict)

```text
⚠️ A memory already exists with this name but has different content.

Existing: test.md - Test Memory
New: test.md - Test Function

  [r] Replace existing  [k] Keep both (rename new)  [c] Cancel
  
Choose: _
```

**If no collision:** Continue to Step 6.

### Step 6: Save Memory

**Ensure type directory exists** (e.g., `preferences/`, `patterns/`). Create if missing.

**Filename:** `{slug}.md`

**Slug:** Generated from title using kebab-case:

- Lowercase
- Replace spaces and non-alphanumeric with hyphens
- Remove leading/trailing hyphens
- Collapse multiple hyphens to single

Example: "SQL Optimization Before Caching" → `sql-optimization-before-caching.md`

**Markdown format (auto-memory compatible):**

```markdown
---
name: sql-optimization-before-caching
description: When facing API latency - optimize SQL queries before adding caching, fix root causes not symptoms
metadata:
  type: feedback
  neat_type: pattern
  tags: [performance, database, optimization]
  intent_triggers: [performance, slow, latency]
  created: 2026-06-24T10:30:00Z
  promoted: false
---

Optimize database queries before adding caching layers when facing API latency.

**Why:** Caching masks symptoms; query optimization fixes root causes. Discovered during API performance debugging - adding Redis cache hid the fact that N+1 queries were still hammering the database.

**How to apply:**
1. Profile to identify slow queries
2. Check for N+1 queries
3. Verify indexes exist
4. Only add caching after optimization

**Source:** 2026-06-24 - API debugging session
```

### Step 7: Update Index

**Order:** (1) Write memory file (2) Update index

Update `.index/index.json`:

```json
{
  "patterns": [
    {
      "file": "sql-optimization-before-caching.md",
      "name": "sql-optimization-before-caching",
      "description": "Optimize SQL queries before adding caching layers",
      "tags": ["performance", "database", "optimization"],
      "triggers": ["performance", "slow", "latency"],
      "created": "2026-06-24T10:30:00Z"
    }
  ]
}
```

**file:** Relative path, not absolute (e.g., `sql-optimization-before-caching.md`)

**Rollback:** If index update fails, delete memory file

### Step 8: Confirm

```text
✓ Captured! Pattern (global)
~/.claude/neat_memory/patterns/sql-optimization-before-caching.md
```

### Step 9: Check Soft Limits (after save)

**Count current memories** of this type (read actual files, not counter).

**If count >= soft_limit AND not recently reminded:**

```text
⚠️  You now have 200 patterns (soft limit: 200).

Location: ~/.claude/neat_memory/patterns/
Consider reviewing and deleting old files manually.
```

**Track reminders:** `.index/cleanup_reminders.json` to avoid repeating every capture:

```json
{
  "patterns": {
    "limit": 200,
    "last_reminded_at": 200
  }
}
```

**Reminder logic:** Warn at soft limit (200), then every +50 (250, 300, 350...).

User reviews files in their file manager/terminal. Index rebuilds automatically on next recall.

## Directory Structure

**Global:** `~/.claude/neat_memory/` → `preferences/`, `patterns/`, `.index/`

**Project:** `{project}/.claude/neat_memory/` → `solutions/`, `lessons/`, `.index/`

## Red Flags

| Thought | Reality |
| ------------------------------- | ---------------------- |
| "User rushed, skip confirmation" | Prevents corruption |
| "Obviously type X" | Can't read minds - ask |
| "Save it, fix later" | Do it right now |
| "Close to existing" | Always check collision |
| "User said 'save everything'" | Content, not bypass |

## Common Mistakes

| Mistake | Rule |
| ------------------------- | ------------------------------------------------ |
| Wrong location | Preference/Pattern → Global; Solution/Lesson → Project |
| Wrong format | JSON, exact schema, type prefix |
| Skipping confirmation | Show preview, get approval |
| Skipping collision check | Always check filename exists before save |
| Not self-contained | Explain WHY, not WHAT |

## Edge Cases

**Multiple types:** Offer separate captures, user decides |
**Filename collision:** Trigger overlap/conflict detection, let user decide |
**Index corrupt:** Rebuild from files, warn |
**Duplicates:** Handled in recall, not capture
