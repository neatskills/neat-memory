# Memory Schema

Memories use **Claude Code auto-memory format** (markdown with YAML frontmatter) plus neat-memory extensions.

## Auto-Memory Compatible Format

**Minimum (auto-memory compatible):**

```markdown
---
name: sql-before-cache
description: Optimize SQL queries before adding caching layers
metadata:
  type: feedback
---

Content with **Why:** and **How to apply:** sections.
```

**Full (with neat-memory extensions):**

```markdown
---
name: sql-before-cache
description: Optimize SQL queries before adding caching layers
metadata:
  type: feedback
  neat_type: pattern
  tags: [performance, database, optimization]
  intent_triggers: [performance, slow, latency]
  created: 2026-06-24T10:30:00Z
  promoted: false
---

Content with **Why:** and **How to apply:** sections.
```

## Type Mappings

| neat_type | Auto-memory type | Location | Purpose |
|---|---|---|---|
| preference | feedback | Global | Personal style/workflow |
| pattern | feedback | Global | Universal principle |
| solution | project | Project | What works here |
| lesson | project | Project | What doesn't work |

## File Naming

**Format:** `{kebab-case-slug}.md`

**Examples:** `verbose-logging.md`, `sql-before-cache.md`, `use-zustand-state.md`

**Location:** Type subdirectory (`preferences/`, `patterns/`, `solutions/`, `lessons/`)

## Complete Example

**File:** `patterns/sql-before-cache.md`

```markdown
---
name: sql-before-cache
description: Optimize SQL queries before adding caching layers
metadata:
  type: feedback
  neat_type: pattern
  tags: [performance, database, optimization, sql]
  intent_triggers: [performance, slow, latency]
  created: 2026-06-24T10:30:00Z
  promoted: false
---

When facing API latency, always optimize database queries before adding caching layers.

**Why:** In one case, Redis caching improved response time by only 15%, while optimizing queries with batch loading improved it by 80%. Caching masks symptoms; query optimization fixes root causes.

**How to apply:**
1. Profile to identify slow queries
2. Check for N+1 queries (batch them)
3. Verify indexes exist
4. Only add caching after query optimization

**Context:** Discovered during API performance debugging. Initially tried Redis caching first, but profiling revealed the real bottleneck was 50+ individual SELECT queries.

**Source:** 2026-06-24 - API performance debugging

**Related:** Extends [[profiling-first]] pattern.
```

## Validation Rules

**name:** Kebab-case slug (`sql-before-cache`, `verbose-logging`)

**description:** One-line summary (used by auto-memory for semantic retrieval)

**metadata.type:** `feedback` | `reference` | `project` | `user` (auto-memory types)

**metadata.neat_type:** `preference` | `pattern` | `solution` | `lesson` (neat types)

**metadata.tags:** Array of 3-7 keywords

**metadata.intent_triggers:** Array of 3-5 search terms

**metadata.created:** ISO 8601 timestamp

**metadata.promoted:** Boolean, defaults to false

## Field Explanations

**promoted:** Set to `true` when memory is copied to auto-memory (prevents re-promotion)

**demoted_from_auto_memory:** Set to `true` when memory originated from auto-memory

**consolidated_into:** Points to consolidated memory's name when merged

## Index Files

Index stored at `.index/index.json`:

```json
{
  "preferences": [
    {
      "file": "verbose-logging.md",
      "name": "verbose-logging",
      "description": "Keep logs detailed for debugging",
      "tags": ["logging", "debugging"],
      "triggers": ["log", "debug"],
      "created": "2026-06-24T10:30:00Z"
    }
  ],
  "patterns": [],
  "solutions": [],
  "lessons": []
}
```

## Auto-Memory MEMORY.md

When promoted, also add to `~/.claude/memory/MEMORY.md`:

```markdown
- [SQL Before Cache](sql-before-cache.md) — Optimize queries before adding caching layers
```
