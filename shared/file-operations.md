# File Operations

Shared patterns for atomic file writes, collision detection, and index
updates used by neat-memory-capture and neat-memory-recall.

## Atomic Memory Write

Write memory file, update index, with collision detection.

**Process:**

1. Generate ID from type prefix and slugified title: `{prefix}_{slug}`
2. Build file path: `{typeDir}/{id}.json`
3. Check if file already exists at path
4. If exists: Load existing memory and check for duplicate (≥0.75 overlap) or conflict
5. If duplicate/conflict: Show appropriate UI, get user choice, handle accordingly
6. If no collision: Write memory file with generated ID, then update index
7. On write failure: Rollback by deleting memory file

**Key principles:**

- Check filename collision BEFORE write
- Trigger overlap/conflict detection on collision
- Memory file write BEFORE index update
- Rollback on failure (delete file only)
- Index file_path is relative to memory root: `patterns/pat_sql_before_cache.json`

## Safe Memory Load

Load memory with error handling.

**Process:**

1. Read JSON file from path
2. Parse JSON content
3. Validate required fields exist: id, type, title, content
4. Return memory object (no modification on read)

**Error handling:**

- JSON.parse fails → log warning, return null, continue with other memories
- File missing → log warning, return null, continue
- Invalid structure → log warning, return null, continue

## Type Mappings

**Directory mapping:**

- `preference` → `preferences/`
- `pattern` → `patterns/`
- `solution` → `solutions/`
- `lesson` → `lessons/`

**Prefix mapping:**

- `preference` → `pref`
- `pattern` → `pat`
- `solution` → `sol`
- `lesson` → `les`

**Slugify:** Lowercase, replace non-alphanumeric with underscore, remove leading/trailing underscores, collapse multiple underscores to single.
