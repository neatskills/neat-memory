# File Operations

Shared patterns for atomic file writes, counter increments, and index
updates used by neat-memory-capture and neat-memory-recall.

## Atomic Counter Increment

Used during memory capture to get next available ID.

**Pattern:**

```javascript
function incrementCounter(type) {
  const counterPath = '.index/counters.json'
  
  // 1. Read current counters
  let counters = readJSON(counterPath) || {
    preferences: 0,
    patterns: 0,
    solutions: 0,
    lessons: 0
  }
  
  // 2. Validate counter hasn't exceeded limit
  if (counters[type] >= 999) {
    throw new Error(`Counter limit reached for ${type}. Archive old memories.`)
  }
  
  // 3. Increment
  counters[type] += 1
  const newCounter = counters[type]
  
  // 4. Write back immediately (before using counter)
  writeJSON(counterPath, counters)
  
  return newCounter
}
```

**Format:** 3-digit zero-padded (001-999)

**Rollover:** Fail with error after 999, prompt user to archive

## Atomic Memory Write

Write memory file, update index, with rollback on failure.

**Pattern:**

```javascript
function writeMemory(memory, type) {
  const typeDir = getTypeDirectory(type) // preferences/, patterns/, etc.
  const filename = `${memory.id}_${slugify(memory.title)}.json`
  const filePath = `${typeDir}/${filename}`
  const indexPath = '.index/index.json'
  
  try {
    // 1. Write memory file
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
    
    // Decrement counter
    decrementCounter(type)
    
    throw new Error(`Failed to write memory: ${error.message}`)
  }
}

function decrementCounter(type) {
  const counterPath = '.index/counters.json'
  let counters = readJSON(counterPath)
  counters[type] -= 1
  writeJSON(counterPath, counters)
}
```

**Key principles:**

- Counter increment BEFORE filename creation
- Memory file write BEFORE index update
- Rollback on any failure (delete file, decrement counter)
- file_path in index is relative to memory root (e.g., `patterns/pat_012_sql-before-cache.json`)

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
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}
```
