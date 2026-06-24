/**
 * Reference implementation for demoting auto-memory to neat-memory
 *
 * This is a reference script showing the demotion logic.
 * Actual implementation happens in SKILL.md workflow.
 */

// ━━━ Demotion Criteria Check ━━━

function isDemotionCandidate(autoMemory) {
  const reasons = [];

  // Parse content
  const content = autoMemory.content || "";
  const wordCount = (content.match(/\S+/g) || []).length;

  // Size check
  if (wordCount > 400) {
    reasons.push(`Too detailed (${wordCount} words > 400)`);
  }

  // Has code examples?
  if (content.includes("```") || content.includes("`")) {
    reasons.push("Contains code examples");
  }

  // Domain-specific? (check for framework/library mentions)
  const domainKeywords = [
    "react", "vue", "angular", "python", "javascript", "typescript",
    "django", "flask", "express", "nextjs", "nuxt", "svelte"
  ];
  const lowerContent = content.toLowerCase();
  const detectedDomains = domainKeywords.filter(kw => lowerContent.includes(kw));
  if (detectedDomains.length > 0) {
    reasons.push(`Domain-specific (${detectedDomains.join(", ")})`);
  }

  // References other concepts? (should be linked in neat-memory)
  const hasReferences = /see also|related to|similar to|extends/i.test(lowerContent);
  if (hasReferences) {
    reasons.push("References other concepts (should use relationships)");
  }

  // If multiple reasons, strong candidate
  if (reasons.length >= 2) {
    return { eligible: true, confidence: "high", reasons };
  } else if (reasons.length === 1) {
    return { eligible: true, confidence: "medium", reasons };
  }

  return { eligible: false, reasons: [] };
}

// ━━━ Type Mapping ━━━

function mapAutoTypeToNeatType(autoType, content) {
  const lowerContent = content.toLowerCase();

  switch (autoType) {
    case "feedback":
      // Check if it's personal workflow or universal principle
      if (/\b(i prefer|my workflow|i use|i like)\b/.test(lowerContent)) {
        return { type: "preference", location: "global" };
      }
      if (/\b(always|never|avoid|don't)\b/.test(lowerContent)) {
        return { type: "pattern", location: "global" };  // Universal principle
      }
      return { type: "preference", location: "global" };  // Default

    case "reference":
      // Check if project-specific or general
      if (/\bthis project|our team|our codebase\b/.test(lowerContent)) {
        return { type: "solution", location: "project" };
      }
      return { type: "pattern", location: "global" };

    case "project":
      // Check if it's "what works" or "what doesn't work"
      if (/\b(failed|broke|bug|issue|problem|avoid|don't)\b/.test(lowerContent)) {
        return { type: "lesson", location: "project" };
      }
      return { type: "solution", location: "project" };

    case "user":
      return { type: "preference", location: "global" };

    default:
      return { type: "preference", location: "global" };
  }
}

// ━━━ Extract Tags from Content ━━━

function extractTags(content, title, detectedDomains = []) {
  const tags = new Set();

  // Add domain tags
  detectedDomains.forEach(d => tags.add(d));

  // Lowercase once for efficient matching
  const lowerContent = content.toLowerCase();
  const lowerTitle = title.toLowerCase();

  // Common technical tags
  const techKeywords = {
    "performance": /\b(performance|slow|fast|optimize|latency|speed)\b/,
    "testing": /\b(test|testing|spec|jest|mocha|cypress)\b/,
    "database": /\b(database|sql|query|index|migration)\b/,
    "api": /\b(api|endpoint|rest|graphql|request)\b/,
    "frontend": /\b(frontend|ui|ux|component|view)\b/,
    "backend": /\b(backend|server|service|middleware)\b/,
    "security": /\b(security|auth|authentication|authorization|secure)\b/,
    "debugging": /\b(debug|debugging|error|bug|issue)\b/
  };

  for (const [tag, pattern] of Object.entries(techKeywords)) {
    if (pattern.test(lowerContent) || pattern.test(lowerTitle)) {
      tags.add(tag);
    }
  }

  // Limit to 7 tags
  return Array.from(tags).slice(0, 7);
}

// ━━━ Extract Intent Triggers ━━━

function extractIntentTriggers(content, title, tags) {
  const triggers = new Set();

  // Add tags as triggers
  tags.forEach(t => triggers.add(t));

  // Extract key phrases from title
  const titleWords = title.toLowerCase().split(/\s+/).filter(w => w.length > 3);
  titleWords.forEach(w => triggers.add(w));

  // Extract verbs (action words)
  const actionWords = content.match(/\b(use|avoid|prefer|optimize|test|debug|fix|implement|configure|setup)\b/gi) || [];
  actionWords.slice(0, 3).forEach(w => triggers.add(w.toLowerCase()));

  // Limit to 5 triggers
  return Array.from(triggers).slice(0, 5);
}

// ━━━ Type Metadata ━━━

const TYPE_CONFIG = {
  "preference": { prefix: "pref", dir: "preferences" },
  "pattern": { prefix: "pat", dir: "patterns" },
  "solution": { prefix: "sol", dir: "solutions" },
  "lesson": { prefix: "les", dir: "lessons" }
};

// ━━━ Helper: Slug conversion ━━━

function toSlug(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

// ━━━ Generate neat-Memory JSON ━━━

function generateNeatMemoryJSON(autoMemory, detectedDomains = []) {
  const { type, location } = mapAutoTypeToNeatType(autoMemory.type, autoMemory.content);

  const slug = toSlug(autoMemory.name || autoMemory.title);
  const prefix = TYPE_CONFIG[type].prefix;

  const id = `${prefix}_${slug}`;

  const tags = extractTags(autoMemory.content, autoMemory.title, detectedDomains);
  const intent_triggers = extractIntentTriggers(autoMemory.content, autoMemory.title, tags);

  return {
    id,
    type,
    location,  // Include location for getNeatMemoryFilePath
    title: autoMemory.title,
    created: new Date().toISOString(),
    tags,
    intent_triggers,
    content: autoMemory.content,
    context: "Demoted from auto-memory - grew too detailed or domain-specific",
    source_session: {
      date: new Date().toISOString().split('T')[0],
      context: `Demoted from auto-memory (${autoMemory.type}), originally captured ${autoMemory.created || 'unknown date'}`
    },
    demoted_from_auto_memory: true
  };
}

// ━━━ File Path Generation ━━━

function getNeatMemoryFilePath(memory, location) {
  const typeDir = TYPE_CONFIG[memory.type].dir;
  const basePath = location === "global"
    ? "~/.claude/neat_memory"
    : ".claude/neat_memory";

  return `${basePath}/${typeDir}/${memory.id}.json`;
}

// ━━━ Example Usage ━━━

const exampleAutoMemory = {
  type: "feedback",
  name: "react-hooks-pattern",
  title: "React Hooks Pattern",
  content: `Use hooks pattern in React components for state management.

Example:
\`\`\`javascript
const [count, setCount] = useState(0);
\`\`\`

Always use useEffect for side effects. Avoid class components.

Related to: component lifecycle, functional programming
`,
  created: "2026-03-15"
};

// Check if demotion candidate
const check = isDemotionCandidate(exampleAutoMemory);
console.log(check);
/*
{
  eligible: true,
  confidence: "high",
  reasons: [
    "Contains code examples",
    "Domain-specific (react, javascript)",
    "References other concepts (should use relationships)"
  ]
}
*/

// Detect domains
const detectedDomains = ["react", "javascript"];

// Generate neat-memory JSON
const neatMemory = generateNeatMemoryJSON(exampleAutoMemory, detectedDomains);
console.log(JSON.stringify(neatMemory, null, 2));
/*
{
  "id": "pat_react_hooks_pattern",
  "type": "pattern",
  "title": "React Hooks Pattern",
  "created": "2026-06-24T10:00:00.000Z",
  "tags": ["react", "javascript", "frontend"],
  "intent_triggers": ["react", "javascript", "hooks", "use", "avoid"],
  "content": "Use hooks pattern in React components...",
  "context": "Demoted from auto-memory - grew too detailed or domain-specific",
  "source_session": {
    "date": "2026-06-24",
    "context": "Demoted from auto-memory (feedback), originally captured 2026-03-15"
  },
  "demoted_from_auto_memory": true
}
*/

// File path (location comes from memory object now)
const filePath = getNeatMemoryFilePath(neatMemory, neatMemory.location);
console.log(filePath);
// ~/.claude/neat_memory/patterns/pat_react_hooks_pattern.json
