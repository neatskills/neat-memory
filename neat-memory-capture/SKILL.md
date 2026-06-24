---
name: neat-memory-capture
description: Use after solving problems, making decisions, or discovering
  patterns - captures experience as JSON memories for cross-session recall
---

# Memory Capture

**Role:** Capture reusable experience as structured memories.

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

| Type | Prefix | Location | Purpose | Soft Limit |
| -------------- | ------ | -------- | ---------------------- | ---------- |
| **Preference** | pref | Global | Personal style/workflow | 200 |
| **Pattern** | pat | Global | Universal principle | 200 |
| **Solution** | sol | Project | What works here | 150 |
| **Lesson** | les | Project | What doesn't work | 150 |

Global = `~/.claude/neat_memory/`; Project = `{project}/.claude/neat_memory/`

**ID:** `{prefix}_{slug}` (e.g., `pat_sql_before_cache`)

**Soft Limits:** Non-blocking recommendations. User can save anyway, raise limit, or cleanup.

*See [../shared/file-operations.md](../shared/file-operations.md) for atomic writes.*

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

**Title:** 3-7 words | **Content:** 200-500 words (WHY, examples,
metrics) | **Context:** Why/when | **Tags:** 3-7 | **Triggers:** 3-5

### Step 4: Generate Preview

```text
Title: [title] | Type: [type] | Tags: [tags]
Triggers: [triggers]
Content: [First 300 chars...] | Location: [path]
[y] Save  [e] Edit  [c] Change type  [n] Cancel: _
```

### Step 5: Handle Feedback

**[y]:** Save | **[e]:** Edit fields → preview → Step 4 |
**[c]:** Return to Step 2 | **[n]:** Cancel

### Step 5.5: Check Filename Collision

**Generate ID and check for collision:**

```text
Checking for existing memory with same name...
```

**If filename exists:**

1. Load existing memory from file
2. Calculate overlap (reuse `shared/duplicate-detection.md` logic)
3. If overlap >= 75%: Show duplicate UI
4. Else: Check conflict (reuse `shared/conflict-detection.md` logic)
5. If conflict: Show conflict UI
6. Else: Show collision UI (same name, different content)

**Duplicate UI:**

```text
━━━ Duplicates Detected ━━━

[1] pat_sql_before_cache - SQL Before Cache (existing)
    Created: 2026-06-20 | Activated: 5 times
    Content: "When facing API latency..."
    
[2] pat_sql_before_cache - SQL Optimization Before Caching (new)
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

Existing: pat_test - Test Memory
New: pat_test - Test Function

  [r] Replace existing  [k] Keep both (rename new)  [c] Cancel
  
Choose: _
```

**If no collision:** Continue to Step 6.

### Step 6: Save Memory

**Filename:** `{prefix}_{slug}.json`

**Slug:** Generated from title using slugify:
- Lowercase
- Replace non-alphanumeric with underscore
- Remove leading/trailing underscores
- Collapse multiple underscores to single

**JSON schema:**

```json
{
  "id": "pat_sql_before_cache",
  "type": "pattern",
  "title": "SQL Optimization Before Caching",
  "created": "2026-06-24T10:30:00Z",
  "tags": ["performance", "database", "optimization"],
  "intent_triggers": ["performance", "slow", "latency"],
  "content": "When facing API latency...",
  "source_session": {"date": "2026-06-24", "context": "API debugging"},
  "context": "Discovered during debugging.",
  "relationships": [],
  "merged_from": []
}
```

### Step 7: Update Index

**Order:** (1) Write memory file (2) Update index

Update `.index/index.json`: `{ "pat_sql_before_cache": { title, type, tags, file_path } }`

**file_path:** Relative, not absolute (e.g., `patterns/pat_sql_before_cache.json`)

**Rollback:** If index update fails, delete memory file (no counter to decrement)

### Step 8: Confirm

```text
✓ Captured! Pattern (global) | ID: pat_sql_before_cache
~/.claude/neat_memory/patterns/pat_sql_before_cache.json
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
