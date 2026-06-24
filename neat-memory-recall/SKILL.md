---
name: neat-memory-recall
description: Use when user asks about past experience, approaches, or
  lessons - queries memories with duplicate detection and synthesis
---

# Memory Recall

**Role:** Search memories and synthesize coherent answers.

## Memory Types and Prefixes

| Type | Prefix | Location | Purpose |
| -------------- | ------ | -------- | ---------------------- |
| **Preference** | pref | Global | Personal style/workflow |
| **Pattern** | pat | Global | Universal principle |
| **Solution** | sol | Project | What works here |
| **Lesson** | les | Project | What doesn't work |

**ID format:** `{prefix}_{slug}` (e.g., `pat_sql_optimization_before_caching`, `sol_use_zustand`)

*See [../shared/file-operations.md](../shared/file-operations.md) for load patterns and type mappings.*

## When to Use

User asks about past experience, approaches, or lessons:

- "How did we handle X before?"
- "What did we learn about Y?"
- "Have I solved this problem already?"
- "What mistakes should I avoid?"

**Do NOT use for:**

- Current session context (use conversation history)
- Documented code patterns (read codebase)
- General knowledge (use web search)
- One-time temporary notes (not captured as memories)

## Process

### Step 1: Parse Query

| Element | Extract |
| ------------ | ----------------------------------------------- |
| **Keywords** | Main topics (performance, auth, testing) |
| **Context** | Knowledge type (approach, fix, decision, avoid) |
| **Scope** | "my"/"I" → Global; "we"/"team" → Project |

### Step 2: Search Memories

1. Search: Project → Global → Combine → Dedupe by ID
2. Match against: `intent_triggers`, `tags`, `title`
3. Read `.index/index.json`, filter, sort by relevance, return top 10

### Step 3: Dispatch Recall Subagent

**Subagent input:**

- Memory IDs from Step 2
- Original query keywords
- Scope (global/project)

**Subagent responsibilities:**

- Load full memory JSON files
- Detect duplicates and conflicts (Steps 4a-4b)
- Handle user interactions (duplicate/conflict UI)
- Synthesize answer (Step 6)
- Return: synthesized answer

**Error handling contract:**

- JSON.parse fails: Log warning, skip memory, continue
- File missing: Log warning, skip memory, continue
- No valid memories: Return "No valid memories found"

**Main context receives:** Synthesized answer (compact)

---

**Subagent Process:**

### Step 4: Detect Duplicates and Conflicts

**A. Check Duplicates** (use `../shared/duplicate-detection.md`):

- Calculate overlap: tags (40%), triggers (30%), content (30%)
- Group transitive overlaps (3+ memories)
- **Only ≥75% overlap triggers handling**

**B. Check Conflicts** (use `../shared/conflict-detection.md`):

- Same type + overlapping domain + contradictory keywords
- **Only strong conflicts trigger handling**
- **Priority: Conflicts → Duplicates**

### Step 4A: Handle Conflicts (if detected)

Use `../shared/conflict-detection.md` for UI:

```text
⚠️ Found contradicting memories:

[1] mem_id - Title
    Content: "..."
[2] mem_id - Title
    Content: "..."

Which applies now?
  [1] Use #1  [2] Use #2  [b] Show both
  [k] Keep both (different contexts)

Choose: _
```

### Step 4B: Handle Duplicates (if detected)

Use `../shared/duplicate-detection.md` for UI:

```text
━━━ Duplicates Detected ━━━

[1] mem_id - Title
    Created: date | Activated: N times | Tags: [tags]
    Location: path
[2] mem_id - Title
    Created: date | Activated: N times | Tags: [tags]
    Location: path

These overlap significantly (XX% similar).

  [b] Use both  [m] Merge  [1] Use only #1  [2] Use only #2
  [k] Keep separate

Choose: _
```

### Step 5: Load Memory Content

See [scripts/load-memory.js](scripts/load-memory.js) for reference
implementation (path relative to skill directory).

**Load process:**

1. Read JSON file from path in index
2. Parse with try/catch (skip on error, log warning)
3. Validate required fields exist
4. Return memory content for synthesis

### Step 6: Synthesize Answer

```text
[Synthesized answer using memory content]

━━━ Memories Used ━━━
• pat_sql_optimization_before_caching - SQL Optimization Before Caching
• les_redis_caching_masked_root_cause - Redis Caching Masked Root Cause

[If merged:] Note: Merged 2 similar memories about SQL optimization.
```

**Guidelines:**

- Combine points
- Attribute insights
- Highlight contradictions
- Actionable, user-focused

## Red Flags - STOP and Follow Skill

| Thought | Reality |
| -------------------------------- | --------------------------------- |
| "User wants answer, not audit" | Duplicate handling IS quality |
| "Showing merge UI wastes time" | UI prevents knowledge rot |
| "User said 'just give answer'" | User doesn't control skill |
| "I'll quietly pick best one" | Auto-merge forbidden |
| "They're in hurry, skip prompt" | Will annoy user MORE later |

**Show duplicate UI. No exceptions.**

### When User Resists

```text
I found 5 memories, but 3 are ≥75% duplicates. Quick choice:

[1] Auto-merge duplicates (recommended)
[2] Show all 5 (includes redundancy)
[3] Skip for now (degrades system quality)

Choose: _
```

**Do NOT:** Skip UI, make choice yourself, synthesize without showing,
rationalize "just this once"

## Common Mistakes

| Mistake | Rule |
| ----------------------------- | ----------------------------- |
| Not showing duplicates | ALWAYS inform when ≥75% overlap |
| Auto-merging | User might want both |
| Missing attribution | Always show memory IDs |
| Forgetting activation | MUST increment + update |
| Synthesizing without loading | MUST load full content |

## Edge Cases

**No memories found:**

```text
No memories found for "[query]".
Try: broader keywords, different phrasing, check if captured
Capture new: /neat-memory-capture
```

**All duplicates:** Show once: "Found 3 similar memories about X".
Let user choose: merge all, pick one, use all

**Contradicting:** See `../shared/conflict-detection.md`

## Performance Notes

- Search index first (fast), load full files only for selected
- Limit to top 10 by relevance
- Optional: cache frequently used memories in session
