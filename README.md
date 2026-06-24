# Neat Memory

Cross-session memory for Claude Code. Capture experience from conversations, recall it in future sessions.

## Quick Start

```bash
git clone https://github.com/neatskills/neat-memory.git
cd neat-memory
./scripts/manage-skills.sh
```

Then use:
- `/neat-memory-capture` - After solving problems or discovering patterns
- `/neat-memory-recall "query"` - Query domain-specific experience (when auto-memory is insufficient)
- `/neat-memory-manager` - Manage quality: merge duplicates, resolve conflicts, promote/demote between systems

## vs. Auto-Memory

Claude Code has built-in auto-memory (`~/.claude/memory/`). neat-memory uses the **same format** but adds:

| | Auto-Memory | neat-memory |
|---|---|---|
| **When** | Always loaded | On-demand via `/neat-memory-recall` |
| **Best for** | Who you are, preferences, current work | Detailed patterns, solutions, lessons |
| **Size** | <300 words | 300-500 words |
| **Format** | `name`, `description`, `metadata.type` | Same + `neat_type`, `tags`, `triggers` |
| **Scope** | Broad, most responses | Domain-specific, when relevant |
| **Management** | Auto-managed by Claude Code | User-curated via `/neat-memory-manager` |

**Same format, different depth:**
- Auto-memory: "Use TDD for skills" (50 words, always-on)
- neat-memory: "TDD Methodology: RED/GREEN/REFACTOR phases, reference docs..." (500 words, TDD queries only)

**neat-memory-manager** syncs both systems:
- Consolidates related memories before promotion (5 → 1 file)
- Promotes neat global → auto global (≤300 words)
- Demotes auto global → neat global (>400 words, detailed)
- Detects cross-system duplicates
- Note: Auto-memory project excluded (auto-managed by Claude Code)

## Memory Types

| Type | Auto-memory type | Location | Example |
|---|---|---|---|
| **Preference** | feedback | Global (`~/.claude/neat_memory/`) | "I prefer verbose logging" |
| **Pattern** | feedback | Global | "Optimize SQL before caching" |
| **Solution** | project | Project (`.claude/neat_memory/`) | "Use Zustand for state" |
| **Lesson** | project | Project | "Don't use Redis for sessions - race conditions" |

**Format:** Auto-memory compatible markdown (name, description, metadata.type)

**Naming:** kebab-case (`sql-before-cache.md`, not `sql_before_cache.md`)

Schema: [memory-schema.md](neat-memory-capture/references/memory-schema.md)

## Example Memory

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

When facing API latency, always optimize queries first.

**Why:** Caching masks symptoms; optimization fixes root causes.

**How to apply:**
1. Profile queries
2. Fix N+1 queries
3. Add indexes
4. Then cache
```

## Migration

If you have existing memories in old format:

```bash
./scripts/migrate-to-auto-format.sh --dry-run  # Preview
./scripts/migrate-to-auto-format.sh            # Execute
./scripts/rebuild-index.sh                     # Rebuild index
```

Backs up originals as `.backup` files.

## License

MIT - See [LICENSE](LICENSE) file

## Contributing

Issues and PRs welcome at [repository URL]
