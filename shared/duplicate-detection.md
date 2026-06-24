# Duplicate Detection and Handling

Shared logic for neat-memory-recall (Step 3-4) and neat-memory-cleanup
(Step 2-3)

## Calculate Overlap

Calculate similarity score between two memories:

1. Tag overlap: intersection size / union size (40% weight)
2. Trigger overlap: intersection size / union size (30% weight)
3. Content similarity: text comparison algorithm (30% weight)
4. Final score: weighted sum of all three

**Categorization:**

- ≥0.75 = high overlap (duplicate)
- ≥0.50 = medium overlap (related)
- <0.50 = low overlap (independent)

**Only ≥0.75 triggers duplicate handling.**

## Group Duplicates

For each memory, check if it overlaps (≥0.75) with any member of existing groups. If yes, add to that group. If no, create new group. Return only groups with 2+ members (transitive grouping).

## User Choice UI

```text
Found memories about [topic]:

━━━ Duplicates Detected ━━━

[1] pat_sql_optimization_before_caching - SQL Optimization Before Caching
    Created: 2026-06-24
    Tags: [performance, database, optimization]
    Location: patterns/pat_sql_optimization_before_caching.json
    
[2] pat_optimize_queries_before_cache - Optimize Queries Before Adding Cache
    Created: 2026-06-25
    Tags: [performance, sql, caching]
    Location: patterns/pat_optimize_queries_before_cache.json

[If 3+ memories, show all numbered]
    
These overlap significantly (XX% similar).

What should I do?
  [b] Use both  [m] Merge  [1] Use only #1  [2] Use only #2  [k] Keep separate

Choose: _
```

**Always:** Show ALL members, metadata (created, activated, tags,
location), exact overlap %, 5 options (b/m/1/2/k)

## Handle User Choice

### [b] Use Both

Load all duplicate memories. In recall: synthesize from all. In manager: skip (no action).

### [m] Merge

1. Show list of duplicates being merged
2. Ask which should be base (1/2/...)
3. Combine content using merge algorithm
4. Show preview with [y] Save / [e] Edit / [n] Cancel
5. If confirmed: Update base file, delete others, update index

### [1], [2], [N] Use Only One

Select memory at index. In recall: load and use only selected. In manager: delete others, keep selected.

### [k] Keep Separate

In recall: synthesize from all without re-showing UI. In manager: no action, keep as-is.

## Merge Algorithm

Start with base memory, then:

1. **Combine tags:** Union of all tags across duplicates
2. **Combine triggers:** Union of all intent_triggers across duplicates
3. **Merge content:** Keep base content, append unique paragraphs from other duplicates (split on double newline, check inclusion)
4. **Keep earliest creation:** Minimum creation timestamp across all duplicates
5. **Add merge metadata:** Store merged_from array with id, title, merged_date for each non-base duplicate

Return merged memory object.

## Common Mistakes

| Mistake | Rule |
| ----------------------------- | -------------------------------------------- |
| Not showing all group members | If 3 overlap, show ALL 3 (not just pairs) |
| Auto-merging | NEVER auto-merge - ALWAYS show UI |
| Merging across types | Only merge within same type (no pref+pat) |
| Not preserving metadata | Keep highest count, recent date, all tags |
| Deleting without confirmation | After [1], confirm deletion, show what |
