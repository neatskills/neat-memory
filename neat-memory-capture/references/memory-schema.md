# Memory JSON Schema

Complete schema for memory files stored in `neat_memory/` directories.

## Schema Structure

```json
{
  // ━━━ Required Fields ━━━
  
  // Identity
  "id": "pat_012",              // Format: {type}_{counter} (pref|pat|sol|les)
  "type": "pattern",            // preference | pattern | solution | lesson
  "title": "Short Name",        // 3-7 words descriptive title
  "created": "2026-06-24T10:30:00Z",  // ISO 8601 timestamp
  
  // Content
  "tags": ["tag1", "tag2", "tag3"],        // 3-7 keywords
  "intent_triggers": ["keyword1", "word2"], // 3-5 search triggers
  "content": "Main insight and approach...", // 200-500 words
  
  // Source tracking
  "source_session": {
    "date": "2026-06-24",           // YYYY-MM-DD
    "context": "What was being worked on"
  },
  
  // ━━━ Optional Fields ━━━
  
  "context": "Background, why this matters",  // Additional context
  
  "relationships": [              // Links to related memories
    {
      "type": "extends",          // supersedes | applies | contradicts | extends
      "id": "pat_001",           // Related memory ID
      "reason": "Why they're related"  // Optional explanation
    }
  ],
  
  "merged_from": [                // Added when duplicates are merged
    {
      "id": "pat_008",
      "title": "Original title",
      "merged_date": "2026-06-24T16:00:00Z"
    }
  ]
}
```

## Memory Types

| Type | Location | Purpose |
| ------- | -------- | ------------------------------ |
| `preference` | Global | Personal style/workflow |
| `pattern` | Global | Universal reusable principle |
| `solution` | Project | What works in this project |
| `lesson` | Project | What doesn't work here |

## File Naming Convention

```text
{type}_{counter}_{slug}.json

Examples:
pref_001_verbose-logging.json
pat_012_sql-before-cache.json
sol_003_zustand-state.json
les_001_redis-sessions.json
```

## Complete Real-World Example

```json
{
  "id": "pat_012",
  "type": "pattern",
  "title": "SQL Optimization Before Caching",
  "created": "2026-06-24T10:30:00Z",
  "activated_count": 5,
  "last_activated": "2026-06-24T15:20:00Z",
  "tags": ["performance", "database", "optimization", "sql"],
  "intent_triggers": ["performance", "slow", "latency"],
  "content": "When facing API latency, always optimize database queries
before adding caching layers. Profile to identify N+1 queries and
missing indexes first. In one case, Redis caching improved response
time by only 15%, while optimizing queries with batch loading improved
it by 80%. Caching masks symptoms; query optimization fixes root
causes.",
  "context": "Discovered during API performance debugging session.
Initially tried Redis caching first (quick win), but profiling revealed
the real bottleneck was 50+ individual SELECT queries that could be
batched.",
  "source_session": {
    "date": "2026-06-24",
    "context": "API performance debugging"
  },
  "relationships": [
    {
      "type": "extends",
      "id": "pat_001",
      "reason": "Applies general profiling pattern to SQL specifically"
    }
  ]
}
```

## Validation Rules

**ID format:** `{type}_{counter}` where type is `pref|pat|sol|les` and
counter is 3+ digits

**Type values:** Must be exactly one of: `preference`, `pattern`,
`solution`, `lesson`

**Timestamps:** Must be valid ISO 8601 format with timezone

**Arrays:** `tags` and `intent_triggers` must have at least 1 element

**Content:** Must be non-empty string

**Activated count:** Must be >= 0

## Index Files

### index.json

```json
{
  "pat_012": {
    "title": "SQL Optimization Before Caching",
    "type": "pattern",
    "tags": ["performance", "database", "optimization"],
    "file_path": "patterns/pat_012_sql-before-cache.json"
  }
}
```

### counters.json

```json
{
  "preferences": 5,
  "patterns": 12,
  "solutions": 8,
  "lessons": 3
}
```

Counter is incremented after each successful capture for that type.
