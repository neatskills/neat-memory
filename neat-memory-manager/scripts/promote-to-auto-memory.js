/**
 * Reference implementation for promoting neat-memory to auto-memory
 *
 * NOTE: Simplified after activation tracking removal (Phase 1 lint).
 * Promotion now based on: type + size + location only.
 * See SKILL.md for current workflow.
 */

// ━━━ Eligibility Check ━━━

function isPromotionCandidate(memory, location) {
  if (memory.promoted) {
    return { eligible: false, reason: "Already promoted" };
  }

  if (location === "project") {
    return { eligible: false, reason: "Project-scoped (not universal)" };
  }

  if (memory.type === "solution") {
    return { eligible: false, reason: "Solutions are always project-specific" };
  }

  // Size check - use match for efficiency
  const wordCount = (memory.content.match(/\S+/g) || []).length;
  if (wordCount > 300) {
    return { eligible: false, reason: `Too detailed (${wordCount} words > 300)` };
  }

  // Type-based eligibility (no activation tracking)
  if (memory.type === "preference" || memory.type === "pattern") {
    return { eligible: true, reason: `${memory.type} type, lightweight (<300 words)` };
  }

  return { eligible: false, reason: "Type not eligible (lesson types rarely promoted)" };
}

// ━━━ Type Mapping ━━━

// All neat-memory types map to auto-memory "feedback"
const AUTO_MEMORY_TYPE = "feedback";

// ━━━ Helper: Kebab-case conversion ━━━

function toKebabCase(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

// ━━━ Generate Auto-Memory Markdown ━━━

function generateAutoMemoryMarkdown(memory) {
  const name = toKebabCase(memory.title);
  const content = memory.content;
  const context = memory.context || "";

  return `---
name: ${name}
description: ${memory.title}
type: ${AUTO_MEMORY_TYPE}
originSessionId: promoted-from-neat-memory
---

${content}

${context ? `\n**Context:** ${context}\n` : ''}
**Source:** Promoted from neat-memory (${memory.id})
`;
}

// ━━━ File Path Generation ━━━

function getAutoMemoryFilePath(projectHash, memory) {
  const kebabTitle = toKebabCase(memory.title);
  return `.claude/projects/${projectHash}/memory/${AUTO_MEMORY_TYPE}_${kebabTitle}.md`;
}

// ━━━ Example Usage ━━━

const exampleMemory = {
  id: "pref_terse_responses",
  type: "preference",
  title: "Keep Responses Terse",
  content: "Keep responses short and concise. No trailing summaries.",
  context: "User finds summaries redundant since they can read diffs.",
  promoted: false
};

// Check eligibility
const check = isPromotionCandidate(exampleMemory, "global");
console.log(check);
// { eligible: true, reason: "preference type, lightweight (<300 words)" }

// Generate markdown
const markdown = generateAutoMemoryMarkdown(exampleMemory);
console.log(markdown);
/*
---
name: keep-responses-terse
description: Keep Responses Terse
type: feedback
originSessionId: promoted-from-neat-memory
---

Keep responses short and concise. No trailing summaries.

**Context:** User finds summaries redundant since they can read diffs.

**Source:** Promoted from neat-memory (pref_terse_responses)
*/

// File path
const filePath = getAutoMemoryFilePath("abc123", exampleMemory);
console.log(filePath);
// .claude/projects/abc123/memory/feedback_keep-responses-terse.md
