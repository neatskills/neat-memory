# Neat Memory

Cross-session memory system for Claude Code. Captures experience from
conversations and recalls it in future sessions, providing continuity
across work.

## The Problem

```text
Session 1: User fixes bug → captures solution
Session 2: NEW session, Claude has zero context → re-explains
```

vs.

```text
Session 1: User fixes bug → captures memory
Session 2: Claude recalls memory → "I recall we fixed this before..."
```

## Features

**Cross-Session Continuity** - Memories persist beyond single
conversations
**Two Storage Scopes** - Global (personal patterns) + Project (team
solutions)
**Duplicate Detection** - Handles overlapping memories at query time
**Context-Efficient Recall** - Subagent pattern minimizes main context
impact
**JSON Schema** - Structured, validated memory format

## Skills

- **neat-memory-capture** - Extract and save session experience as
  structured memories
- **neat-memory-recall** - Query memories with duplicate/conflict
  detection and synthesis (uses subagent for efficiency)

## Install

```bash
git clone https://github.com/neatskills/neat-memory.git
cd neat-memory
./scripts/manage-skills.sh  # Defaults to install
```

To uninstall:

```bash
./scripts/manage-skills.sh uninstall
```

## Usage

### Capture Memory

```bash
# After solving a problem or learning something:
/neat-memory-capture

# Choose type:
#   1. Preference - Personal style (global)
#   2. Pattern - Reusable principle (global)
#   3. Solution - What works here (project)
#   4. Lesson - What doesn't work here (project)

# Review preview, confirm, done!
```

### Recall Memory

```bash
# Query past experience:
/neat-memory-recall "How did we handle API performance?"

# System:
# - Searches global + project memories (lightweight index search)
# - Dispatches subagent to minimize context impact
# - Subagent: loads files, detects conflicts/duplicates, handles UI
# - Asks you how to handle conflicts/duplicates
# - Synthesizes answer from selected memories
# - Shows which memories were used
# - Main context only receives compact synthesized answer
```

## Memory Types

| Type | Location | Purpose | Example |
| -------------- | -------- | --------------------- | --------------------- |
| **Preference** | Global | Personal style | "I prefer verbose" |
| **Pattern** | Global | Universal principle | "Optimize SQL first" |
| **Solution** | Project | What works here | "Use Zustand" |
| **Lesson** | Project | What doesn't work | "Redis races" |

**Global** (`~/.claude/neat_memory/`) - Your personal cross-project
knowledge
**Project** (`{project}/.claude/neat_memory/`) - Team-shared project
knowledge

## Directory Structure

### Global (Personal)

```text
~/.claude/neat_memory/
  preferences/
    pref_verbose_logging.json
  patterns/
    pat_sql_before_cache.json
  .index/
    index.json
```

### Project (Team)

```text
{project}/.claude/neat_memory/
  solutions/
    sol_zustand_state.json
  lessons/
    les_redis_sessions_unsafe.json
  .index/
    index.json
```

## Memory Schema

Memories are stored as JSON with strict schema:

```json
{
  "id": "pat_sql_before_cache",
  "type": "pattern",
  "title": "SQL Optimization Before Caching",
  "created": "2026-06-24T10:30:00Z",
  "tags": ["performance", "database", "optimization"],
  "intent_triggers": ["performance", "slow", "latency"],
  "content": "When facing API latency...",
  "source_session": {
    "date": "2026-06-24",
    "context": "API performance debugging"
  }
}
```

See [memory-schema.md](neat-memory-capture/references/memory-schema.md)
for complete schema.

## Design Principles

1. **Fast capture** - Minimal friction to save knowledge
2. **User control** - Never auto-merge, auto-delete, or hide
   conflicts/duplicates
3. **Transparency** - Always show which memories were used
4. **DRY** - Shared logic for duplicate and conflict detection
   (no duplication)
5. **Team-friendly** - Project memories git-versioned for collaboration
6. **Context-efficient** - Subagent pattern keeps main context clean
7. **Simple** - No usage tracking overhead, just pure knowledge storage

## Development Status

- [x] Skill design and testing
- [ ] Installation script
- [ ] Git integration guide
- [ ] Migration from other systems

## License

MIT - See [LICENSE](LICENSE) file

## Contributing

Issues and PRs welcome at [repository URL]
