# Conflict Detection and Handling

Shared logic for neat-memory-recall (when query matches contradicting
memories) and neat-memory-cleanup (Step 2)

## What is a Conflict?

Memories with overlapping intent but contradictory guidance.

**Examples:**

- `pref_001: "verbose logging"` vs `pref_005: "minimal logging"` → Same
  domain, opposite advice
- `sol_003: "Use Redux"` vs `sol_012: "Use Zustand"` → Same problem,
  different solutions

**NOT conflicts:** `pat_001: "SQL before cache"` + `les_001: "Redis
masked root cause"` → Complementary

## Detect Conflicts

```javascript
function detectConflict(mem1, mem2) {
  // 1. Must have overlapping domain (tags/triggers)
  const domainOverlap = intersection(mem1.tags, mem2.tags).length > 0
    || intersection(mem1.intent_triggers,
      mem2.intent_triggers).length > 0
  if (!domainOverlap) return false
  
  // 2. Must be same type (cross-type conflicts NOT flagged -
  // solutions can override global preferences)
  if (mem1.type !== mem2.type) return false
  
  // 3. Must have contradictory indicators
  const contradictoryPairs = [
    ['prefer', 'avoid'], ['use', "don't use"], ['always', 'never'],
    ['enable', 'disable'], ['verbose', 'minimal'],
    ['detailed', 'concise'], ['yes', 'no']
  ]
  
  for (const [word1, word2] of contradictoryPairs) {
    const mem1Has = containsWord(mem1.content, word1)
      || containsWord(mem1.title, word1)
    const mem2Has = containsWord(mem2.content, word2)
      || containsWord(mem2.title, word2)
    if (mem1Has && mem2Has) return true
    
    const mem1HasOpposite = containsWord(mem1.content, word2)
      || containsWord(mem1.title, word2)
    const mem2HasOpposite = containsWord(mem2.content, word1)
      || containsWord(mem2.title, word1)
    if (mem1HasOpposite && mem2HasOpposite) return true
  }
  return false
}

function containsWord(text, word) {
  return new RegExp(`\\b${word}\\b`, 'i').test(text)
}
```

**Only flag strong conflicts** (clear contradiction with opposite
keywords)

## User Choice UI

```text
⚠️ Found contradicting memories:

[1] pref_001 - Verbose Error Logging
    Created: 2026-01-15 | Activated: 5 times
    Content: "I prefer verbose error logging with stack traces..."
    Tags: [logging, debugging, errors]
    Location: preferences/pref_001_verbose-error-logs.json
    
[2] pref_005 - Minimal Logging
    Created: 2026-05-20 | Activated: 3 times
    Content: "I prefer minimal logging to reduce noise..."
    Tags: [logging, production, performance]
    Location: preferences/pref_005_minimal-logging.json

These contradict each other about logging preferences.

Which applies now?
  [1] Use pref_001 (verbose)  [2] Use pref_005 (minimal)  
  [b] Show both (decide by context)  [d] Delete one (resolve permanently)  
  [k] Keep both (apply in different contexts)

Choose: _
```

## Handle User Choice

### [1] or [2] - Use One

```javascript
const selected = memories[index - 1]
// In recall: Use only selected for synthesis
// In cleanup: Offer to delete other
if (inCleanup && confirmed) {
  console.log(`Delete ${memories[1 - index].id}? [y/n]: _`)
  if (confirmed) deleteMemory(memories[1 - index])
}
```

### [b] - Show Both

```javascript
// In recall: Synthesize showing both perspectives with caveat
// In cleanup: No action
```

### [d] - Delete One

```javascript
console.log("Which to delete?\n[1] Delete pref_001\n[2] Delete pref_005\n[n] Cancel")
const choice = getUserInput()
if (choice !== 'n') deleteMemory(memories[parseInt(choice) - 1])
```

### [k] - Keep Both

```javascript
console.log("Add context note to clarify when each applies? [y/n]: _")
if (yes) {
  console.log("When does pref_001 apply?: _")
  memory1.context += `\n\nApplies when: ${getUserInput()}`
  console.log("When does pref_005 apply?: _")
  memory2.context += `\n\nApplies when: ${getUserInput()}`
  saveMemory(memory1); saveMemory(memory2)
}
```

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
pref_001: "I prefer X" (6 months ago)
pref_005: "I prefer Y" (yesterday)
Looks like preference change. Suggest: Delete older? [y/n]: _
```

**Conflict across scopes:**

```text
Global pref_001: "I prefer X"
Project sol_003: "Use Y" (contradicts global)
Might be intentional (project override). Keep both? [y/n]: _
```

**Partial conflicts:**

```text
mem1: "verbose logging + detailed errors"
mem2: "minimal logging + detailed errors"
Conflict on logging, agreement on errors. Consider splitting.
```
