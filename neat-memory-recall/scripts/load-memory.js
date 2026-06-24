// Minimal reference snippet - see ../shared/file-operations.md for full pattern
// Production code should include: error handling, validation, activation tracking
const memory = JSON.parse(fs.readFileSync(filepath))
loadedMemories.push({ id: memory.id, title: memory.title, filepath })
