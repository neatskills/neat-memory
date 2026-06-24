# Conflict Detection and Handling

Shared logic for neat-memory-recall (when query matches contradicting
memories) and neat-memory-cleanup (Step 2)

## What is a Conflict?

Memories with overlapping intent but contradictory guidance.

**Examples:**

- `pref_verbose_logging: "verbose logging"` vs `pref_minimal_logging: "minimal logging"` → Same
  domain, opposite advice
- `sol_use_redux: "Use Redux"` vs `sol_use_zustand: "Use Zustand"` → Same problem,
  different solutions

**NOT conflicts:** `pat_sql_before_cache: "SQL before cache"` + `les_redis_masked_root_cause: "Redis
masked root cause"` → Complementary

## Detect Conflicts

Three conditions must all be true:

1. **Overlapping domain:** Memories share at least one tag OR intent_trigger
2. **Same type:** Both same memory type (cross-type conflicts ignored - project solutions can override global preferences)
3. **Contradictory keywords:** At least one contradictory pair found in title/content

**Contradictory pairs:**

- prefer/avoid, use/don't use, always/never, enable/disable
- verbose/minimal, detailed/concise, yes/no

Check using word boundary regex (case-insensitive).

**Only flag strong conflicts** with clear opposite keywords.

## User Choice UI

```text
⚠️ Found contradicting memories:

[1] pref_verbose_error_logs - Verbose Error Logging
    Created: 2026-01-15
    Content: "I prefer verbose error logging with stack traces..."
    Tags: [logging, debugging, errors]
    Location: preferences/pref_verbose_error_logs.json
    
[2] pref_minimal_logging - Minimal Logging
    Created: 2026-05-20
    Content: "I prefer minimal logging to reduce noise..."
    Tags: [logging, production, performance]
    Location: preferences/pref_minimal_logging.json

These contradict each other about logging preferences.

Which applies now?
  [1] Use pref_verbose_error_logs (verbose)
  [2] Use pref_minimal_logging (minimal)
  [b] Show both (decide by context)
  [d] Delete one (resolve permanently)
  [k] Keep both (apply in different contexts)

Choose: _
```

## Handle User Choice

### [1] or [2] - Use One

Select memory at index. In recall: Use only selected for synthesis. In manager: Offer to delete the other, confirm before deletion.

### [b] - Show Both

In recall: Synthesize showing both perspectives with caveat about contradiction. In manager: No action taken.

### [d] - Delete One

Ask which to delete (1/2/n for cancel). If not cancelled, delete selected memory file and update index.

### [k] - Keep Both

Ask if user wants to add context notes. If yes, prompt for "When does X apply?" for each memory, append to context field, save both files.

## Conflict vs Duplicate

| Aspect | Duplicate | Conflict |
| -------------- | ----------------------- | ------------------- |
| **Content** | Very similar (≥75%) | Different content |
| **Guidance** | Same advice repeated | Opposite advice |
| **Tags** | High overlap | Some overlap |
| **Resolution** | Merge or keep one | Choose context/del. |
| **Example** | "SQL optimization" 2x | "Redis" vs "Postgres" |

**Key:** Duplicates = redundancy; Conflicts = contradiction

## When to Check

**In recall:** Check when multiple memories match query; if 2+ have
same type + overlapping tags → check conflict → show UI before
synthesis

**In cleanup:** Scan all same-type memories → group by overlapping
tags → check each group → present all conflicts

## Common Mistakes

| Mistake | Rule |
| --------------------------------------- | ------------------------------- |
| Confusing duplicates with conflicts | Different resolution strategies |
| Auto-resolving conflicts | NEVER auto-choose - always show |
| Flagging complementary as conflicts | Need actual contradiction |
| Not providing context option | User might want both |

## Edge Cases

**Conflict with self (outdated):**

```text
pref_verbose_logging: "I prefer X" (6 months ago)
pref_minimal_logging: "I prefer Y" (yesterday)
Looks like preference change. Suggest: Delete older? [y/n]: _
```

**Conflict across scopes:**

```text
Global pref_verbose_logging: "I prefer X"
Project sol_use_minimal_logging: "Use Y" (contradicts global)
Might be intentional (project override). Keep both? [y/n]: _
```

**Partial conflicts:**

```text
mem1: "verbose logging + detailed errors"
mem2: "minimal logging + detailed errors"
Conflict on logging, agreement on errors. Consider splitting.
```
