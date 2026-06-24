# Duplicate Detection and Handling

Shared logic for neat-memory-recall (Step 3-4) and neat-memory-cleanup
(Step 2-3)

## Calculate Overlap

```javascript
function calculateOverlap(mem1, mem2) {
  let score = 0.0
  
  // Tag (40%), Trigger (30%), Content similarity (30%)
  const tagOverlap = intersection(mem1.tags, mem2.tags).length /
    union(mem1.tags, mem2.tags).length
  const triggerOverlap = intersection(mem1.intent_triggers,
    mem2.intent_triggers).length /
    union(mem1.intent_triggers, mem2.intent_triggers).length
  const contentSimilarity = calculateContentSimilarity(mem1.content,
    mem2.content)
  
  return (tagOverlap * 0.4) + (triggerOverlap * 0.3) + (contentSimilarity * 0.3)
}

function categorizeOverlap(score) {
  if (score >= 0.75) return "high_overlap"    // Very similar
  if (score >= 0.50) return "medium_overlap"  // Related
  return "low_overlap"                        // Independent
}
```

**Only ≥75% is duplicate.**

## Group Duplicates

```javascript
const groups = []
for (const mem of memories) {
  let addedToGroup = false
  for (const group of groups) {
    for (const groupMem of group) {
      if (calculateOverlap(mem, groupMem) >= 0.75) {
        group.push(mem)
        addedToGroup = true
        break
      }
    }
    if (addedToGroup) break
  }
  if (!addedToGroup) groups.push([mem])
}
return groups.filter(g => g.length >= 2)
```

## User Choice UI

```text
Found memories about [topic]:

━━━ Duplicates Detected ━━━

[1] pat_sql_optimization_before_caching - SQL Optimization Before Caching
    Created: 2026-06-24 | Activated: 3 times
    Tags: [performance, database, optimization] | Location: patterns/pat_sql_optimization_before_caching.json
    
[2] pat_optimize_queries_before_cache - Optimize Queries Before Adding Cache
    Created: 2026-06-25 | Activated: 1 times
    Tags: [performance, sql, caching] | Location: patterns/pat_optimize_queries_before_cache.json

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

```javascript
const contents = duplicates.map(d => loadMemory(d.file_path))
// In recall: synthesize from all
// In cleanup: skip (no action)
```

### [m] Merge

```javascript
console.log("Merging:")
duplicates.forEach(d => console.log(`- ${d.title}`))
console.log("Which should be base? [1/2/...]: _")
const base = duplicates[getUserInput() - 1]
const mergedContent = combineContent(duplicates, base)
console.log("Merged preview:\n", mergedContent,
  "\n[y] Save  [e] Edit  [n] Cancel: _")
if (confirmed) { /* Update base, delete others, update index */ }
```

### [1], [2], [N] Use Only One

```javascript
const selected = duplicates[index - 1]
// In recall: load and use only this one
// In cleanup: delete others, keep selected
```

### [k] Keep Separate

```javascript
// In recall: synthesize from all without showing UI
// In cleanup: no action, keep as-is
```

## Merge Algorithm

```javascript
function combineContent(duplicates, base) {
  let merged = { ...base }
  
  // Combine tags (union)
  const allTags = new Set()
  duplicates.forEach(d => d.tags.forEach(t => allTags.add(t)))
  merged.tags = Array.from(allTags)
  
  // Combine triggers (union)
  const allTriggers = new Set()
  duplicates.forEach(d =>
    d.intent_triggers.forEach(t => allTriggers.add(t)))
  merged.intent_triggers = Array.from(allTriggers)
  
  // Combine content (append unique parts)
  merged.content = mergeTextContent(duplicates.map(d => d.content),
    base.content)
  
  // Keep highest activation count
  merged.activated_count = Math.max(...duplicates.map(d =>
    d.activated_count))
  
  // Keep most recent activation
  const activations = duplicates.filter(d => d.last_activated)
    .map(d => new Date(d.last_activated))
  if (activations.length > 0)
    merged.last_activated = new Date(Math.max(...activations))
      .toISOString()
  
  // Add merge metadata
  merged.merged_from = duplicates.filter(d => d.id !== base.id)
    .map(d => ({ id: d.id, title: d.title,
      merged_date: new Date().toISOString() }))
  
  return merged
}

function mergeTextContent(contents, baseContent) {
  let result = baseContent
  for (const content of contents) {
    if (content === baseContent) continue
    const paragraphs = content.split('\n\n')
    for (const para of paragraphs) {
      if (!result.includes(para.trim())) result += '\n\n' + para
    }
  }
  return result.trim()
}
```

## Common Mistakes

| Mistake | Rule |
| ----------------------------- | -------------------------------------------- |
| Not showing all group members | If 3 overlap, show ALL 3 (not just pairs) |
| Auto-merging | NEVER auto-merge - ALWAYS show UI |
| Merging across types | Only merge within same type (no pref+pat) |
| Not preserving metadata | Keep highest count, recent date, all tags |
| Deleting without confirmation | After [1], confirm deletion, show what |
