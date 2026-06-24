# File Operations

Shared patterns for atomic file writes, collision detection, and index
updates used by neat-memory-capture and neat-memory-recall.

## Atomic Memory Write

Write memory file, update index, with collision detection.

**Pattern:**

```javascript
function writeMemory(memory, type) {
  const typeDir = getTypeDirectory(type) // preferences/, patterns/, etc.
  const slug = slugify(memory.title)
  const id = `${getTypePrefix(type)}_${slug}`
  const filename = `${id}.json`
  const filePath = `${typeDir}/${filename}`
  const indexPath = '.index/index.json'
  
  // Check for filename collision
  if (fileExists(filePath)) {
    const existingMemory = readJSON(filePath)
    
    // Calculate overlap (use shared/duplicate-detection.md logic)
    const overlapScore = calculateOverlap(memory, existingMemory)
    
    if (overlapScore >= 0.75) {
      // Show duplicate UI and get user choice
      const choice = showDuplicateUI([existingMemory], memory)
      return handleDuplicateChoice(choice, existingMemory, memory, filePath, indexPath)
    }
    
    // Check for conflict (use shared/conflict-detection.md logic)
    const isConflict = detectConflict(memory, existingMemory)
    
    if (isConflict) {
      // Show conflict UI and get user choice
      const choice = showConflictUI([existingMemory], memory)
      return handleConflictChoice(choice, existingMemory, memory, filePath, indexPath)
    }
    
    // Same filename but not duplicate/conflict - collision
    const choice = showCollisionUI(existingMemory, memory)
    return handleCollisionChoice(choice, existingMemory, memory, filePath, indexPath)
  }
  
  try {
    // 1. Write memory file
    memory.id = id
    writeJSON(filePath, memory)
    
    // 2. Update index
    let index = readJSON(indexPath) || {}
    index[memory.id] = {
      title: memory.title,
      type: memory.type,
      tags: memory.tags,
      file_path: `${typeDir}/${filename}` // Relative to memory root
    }
    writeJSON(indexPath, index)
    
    return { success: true, path: filePath }
    
  } catch (error) {
    // Rollback: Delete memory file if index update failed
    if (fileExists(filePath)) {
      deleteFile(filePath)
    }
    
    throw new Error(`Failed to write memory: ${error.message}`)
  }
}
```

**Key principles:**

- Check filename collision BEFORE write
- Trigger overlap/conflict detection on collision
- Memory file write BEFORE index update
- Rollback on failure (delete file only, no counter to decrement)
- file_path in index is relative to memory root (e.g., `patterns/pat_sql_before_cache.json`)

## Safe Memory Load

Load memory with error handling and activation tracking.

**Pattern:**

```javascript
function loadMemory(filePath) {
  try {
    // 1. Read and parse JSON
    const memory = readJSON(filePath)
    
    // 2. Validate required fields
    if (!memory.id || !memory.type || !memory.title || !memory.content) {
      console.warn(`Invalid memory structure in ${filePath}`)
      return null
    }
    
    // 3. Default missing activation fields (backward compatibility)
    memory.activated_count = memory.activated_count || 0
    memory.last_activated = memory.last_activated || null
    
    // 4. Update activation tracking
    const updatedMemory = {
      ...memory,
      activated_count: memory.activated_count + 1,
      last_activated: new Date().toISOString()
    }
    
    // 5. Write back updated memory (atomic update)
    writeJSON(filePath, updatedMemory)
    
    // 6. Return updated memory
    return updatedMemory
    
  } catch (error) {
    console.warn(`Failed to load memory from ${filePath}: ${error.message}`)
    return null
  }
}
```

**Error handling:**

- JSON.parse fails → log warning, return null, continue with other memories
- File missing → log warning, return null, continue
- Invalid structure → log warning, return null, continue
- Missing activation fields → default to 0/null (backward compatibility)

## Type Directory Mapping

```javascript
function getTypeDirectory(type) {
  const typeMap = {
    'preference': 'preferences',
    'pattern': 'patterns',
    'solution': 'solutions',
    'lesson': 'lessons'
  }
  return typeMap[type] || type + 's'
}

function getTypePrefix(type) {
  const prefixMap = {
    'preference': 'pref',
    'pattern': 'pat',
    'solution': 'sol',
    'lesson': 'les'
  }
  return prefixMap[type]
}
```

## Helper Functions

```javascript
function readJSON(path) {
  const content = fs.readFileSync(path, 'utf8')
  return JSON.parse(content)
}

function writeJSON(path, data) {
  fs.writeFileSync(path, JSON.stringify(data, null, 2), 'utf8')
}

function fileExists(path) {
  return fs.existsSync(path)
}

function deleteFile(path) {
  fs.unlinkSync(path)
}

function slugify(text) {
  return text.toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')
    .replace(/_+/g, '_')
}
```
