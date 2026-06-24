---
name: neat-memory-manager
description: Manage memories across both systems - merge duplicates, resolve conflicts, promote to auto-memory, demote from auto-memory
---

# Memory Manager

Manage memory quality and cross-system synchronization.

## When to Use

Clean up duplicates/conflicts, promote/demote between systems, optimize organization.

**Triggers:** Manual `/neat-memory-manager`, "manage/organize/sync memories"
**Skip:** Never auto-run or suggest unprompted

## Process

### Step 1: Scan Memories

**Scope:** Manage neat-memory (global + current project) and auto-memory global only.

| System | Location | Types |
|--------|----------|-------|
| neat-memory global | `~/.claude/neat_memory/` | preferences, patterns |
| neat-memory project | `.claude/neat_memory/` (relative to PWD) | solutions, lessons |
| auto-memory global | `~/.claude/memory/` | user, feedback |

**Note:** Auto-memory project (`~/.claude/projects/{hash}/memory/`) is auto-managed by Claude Code and excluded from manual curation.

**If missing:** Create empty index or skip type directory, treat as 0 memories.

Show count summary per system and total.

### Step 2: Detect Issues

Run detection across the 3 locations in priority order:

1. **Cross-system duplicates** - Same content in neat-memory vs auto-memory global
2. **Conflicts** - Use `../shared/conflict-detection.md`
3. **Duplicates within each location** - Use `../shared/duplicate-detection.md` (≥75%)
4. **Promotion candidates** - neat global → auto global eligibility
5. **Demotion candidates** - auto global → neat global eligibility

Show summary with counts, offer choices [1-6] including skip.

### Step 3: Handle Cross-System Duplicates

Detect same knowledge in both systems (exact match or high overlap).

**UI:**

```text
━━━ Cross-System Duplicate Detected ━━━

neat-memory: pref_terse_responses (global)
  Created: 2026-05-15 | Size: 450 words
  Content: "Keep responses short. [detailed methodology...]"

auto-memory: feedback_terse_responses
  Created: 2026-06-01 | Size: 120 words
  Content: "Keep responses short. No summaries."

Same knowledge exists in both systems.

Actions:
  [a] Keep auto-memory (remove from neat, simpler version is enough)
  [n] Keep neat-memory (remove from auto, want detailed version)
  [b] Keep both (mark as reviewed, they serve different purposes)
  [m] Merge into one system
  
Choose: _
```

Choices delete opposite system, mark as reviewed, or merge into chosen system.

### Step 4: Handle Conflicts

Use `../shared/conflict-detection.md` logic. Show UI with contradicting pair. Choices: [1/2] use one (archive other to `.archive/`), [b] show both, [k] keep both with context clarification.

### Step 5: Handle Duplicates

Use `../shared/duplicate-detection.md` logic (≥75% overlap). Show UI with group members. Choices: [b] use both, [m] merge, [1/2] use one, [k] keep separate. Merge combines content/tags/triggers, updates merged_from, deletes sources, updates index.

### Step 6: Review Promotion Candidates (neat global → auto global)

**Scope:** Only global memories can be promoted (project memories stay in their respective systems).

**Criteria:** In `~/.claude/neat_memory/` + ≤300 words + not promoted + type preference/pattern

**A. Detect Consolidation Opportunities**

Before showing individual promotion prompts, check for related memories:

**Consolidation criteria:**
- ≥3 memories eligible for promotion
- Shared topic/tags (≥50% of memories share at least one primary tag)
- Total words ≤800 after consolidation
- Same or compatible types (all preferences, or all patterns)

**If consolidation opportunity found:**

```text
━━━ Consolidation Opportunity ━━━

Found 5 related preferences about "skill development":

  [1] extract-code-to-scripts (109 words)
  [2] json-comments-for-schemas (85 words)
  [3] tdd-skill-structure (263 words)
  [4] real-professional-roles (122 words)
  [5] github-personal-commits (96 words)

Total: 675 words across 5 files
Shared tags: [skills, documentation]

Promoting separately = 5 auto-memory files (always loaded)
Consolidating first = 1 auto-memory file (more efficient)

Options:
  [c] Consolidate into one, then promote
  [s] Promote separately (5 files)
  [p] Partial (choose which to consolidate)
  [k] Skip promotion
  
Choose: _
```

**If [c] Consolidate:**

1. Ask for consolidated title (suggest: "{shared topic} Best Practices")
2. Generate consolidated markdown:
   - Frontmatter: combined tags/triggers, `consolidated_from: [names]`
   - Body: sections per original memory with headers
3. Save to neat-memory: `{slug}.md`
4. Update originals: add `consolidated_into: "{new-name}"` to frontmatter
5. THEN proceed to promote the consolidated memory
6. Show paths for consolidated file and originals

**If [s] Separate:**

Continue to individual promotion prompts below

**If [p] Partial:**

Show checkboxes to select which memories to consolidate, then proceed as [c] for selected

**If [k] Skip:**

Exit promotion step

**B. Individual Promotion (if no consolidation or after consolidation)**

For each eligible memory (or consolidated memory):

```text
━━━ Promotion Candidate ━━━

Name: sql-before-cache
Title: SQL Optimization Before Caching
Type: pattern
Words: 172
Tags: [performance, database, optimization]

Promote to auto-memory global? (will be always-on)
  [y] Yes  [n] No
  
Choose: _
```

**If yes:**

1. Copy markdown file to `~/.claude/memory/`
2. Update frontmatter in neat-memory: `promoted: true`
3. Add to `~/.claude/memory/MEMORY.md` index
4. Show both paths

### Step 7: Review Demotion Candidates (auto global → neat global)

**Scope:** Only global memories can be demoted (project memories stay in their respective systems).

**Criteria:** In `~/.claude/memory/` + (>400 words OR has code blocks OR domain-specific)

**UI:**

```text
━━━ Demotion Candidate ━━━

Name: detailed-debugging-workflow
Title: Detailed Debugging Workflow
Words: 450
Has code blocks: Yes
Domain: debugging

This is too detailed for always-on auto-memory.
Demote to neat-memory (on-demand)?

  [y] Yes (move to neat-memory)
  [k] Keep in auto-memory
  [n] Skip
  
Choose: _
```

**If [y] Yes:**

1. Parse markdown frontmatter
2. Map auto-memory type → neat-memory type:
   - `feedback` → `preference` or `pattern` (ask user which)
   - `user` → `preference`
   - `project` → `solution` or `lesson` (shouldn't happen for global)
   - `reference` → `pattern`
3. Add `demoted_from_auto_memory: true` to frontmatter
4. Save to `~/.claude/neat_memory/{type}/`
5. Ask user to manually remove from `~/.claude/memory/` (show path)
6. Update neat-memory index

### Step 8: Update Indexes

Rebuild `.index/index.json` from filesystem, update `MEMORY.md` if auto-memory changed.

### Step 9: Summary

Show actions taken (resolved, archived, merged, promoted, demoted), before/after counts, remind to run manually when needed.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Auto-merge duplicates" | User must choose - might want both perspectives |
| "Delete without archiving" | Archive first - user can recover |
| "Promote everything frequently used" | Check size and scope - not all belong in auto |
| "Skip cross-system check" | Critical - prevents data duplication |
| "Promote project-scoped memories" | Never - defeats purpose of global/project separation |
| "Include auto-memory project" | No - Claude Code auto-manages it, we only curate neat-memory |

## Common Mistakes

| Mistake | Rule |
|---------|------|
| Promoting project memories | Never - only global memories can be promoted/demoted |
| Promoting solutions | Never promote - always project-specific |
| Auto-promoting without confirmation | Always ask - assisted mode |
| Deleting instead of archiving | Archive conflicts/duplicates to `.archive/` |
| Not updating indexes | Always rebuild after batch operations |
| Promoting >300 word memories | Too detailed for auto-memory |
| Including auto-memory project | Never - it's auto-managed by Claude Code |

## Edge Cases

**Old memories:**

- All memories eligible based purely on type, location, and size
- No historical usage tracking needed

**Empty systems:** Skip relevant detection passes.
**No issues:** Report "well-organized", show scan count, exit.
