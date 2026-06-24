#!/bin/bash
# Don't exit on error in loops - we want to process all files
set +e

# Migrate neat-memory from JSON to Markdown format
# Usage: ./scripts/migrate-to-markdown.sh [--dry-run]

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
  DRY_RUN=true
  echo "DRY RUN MODE - No files will be modified"
  echo ""
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counters
MIGRATED=0
SKIPPED=0
ERRORS=0

# Function to convert JSON to Markdown
convert_json_to_md() {
  local json_file="$1"
  local dir=$(dirname "$json_file")

  # Read JSON
  if ! json_content=$(cat "$json_file"); then
    echo -e "${RED}✗${NC} Failed to read: $json_file"
    ((ERRORS++))
    return 1
  fi

  # Extract fields using jq
  if ! name=$(echo "$json_content" | jq -r '.id // empty' | sed 's/^[^_]*_//'); then
    echo -e "${RED}✗${NC} Failed to parse: $json_file"
    ((ERRORS++))
    return 1
  fi

  type=$(echo "$json_content" | jq -r '.type // empty')
  title=$(echo "$json_content" | jq -r '.title // empty')
  created=$(echo "$json_content" | jq -r '.created // empty')
  tags=$(echo "$json_content" | jq -r '.tags // []')
  triggers=$(echo "$json_content" | jq -r '.intent_triggers // []')
  content=$(echo "$json_content" | jq -r '.content // empty')
  context=$(echo "$json_content" | jq -r '.context // empty')
  promoted=$(echo "$json_content" | jq -r '.promoted // false')
  demoted=$(echo "$json_content" | jq -r '.demoted_from_auto_memory // false')
  consolidated=$(echo "$json_content" | jq -r '.consolidated_into // empty')
  source_date=$(echo "$json_content" | jq -r '.source_session.date // empty')
  source_context=$(echo "$json_content" | jq -r '.source_session.context // empty')

  # Generate markdown filename
  md_file="${dir}/${name}.md"

  # Generate markdown content
  cat > /tmp/memory_temp.md <<EOF
---
name: ${name}
type: ${type}
title: ${title}
created: ${created}
tags: ${tags}
intent_triggers: ${triggers}
promoted: ${promoted}
EOF

  # Add optional fields
  if [ "$demoted" != "false" ] && [ "$demoted" != "null" ]; then
    echo "demoted_from_auto_memory: ${demoted}" >> /tmp/memory_temp.md
  fi

  if [ -n "$consolidated" ] && [ "$consolidated" != "null" ]; then
    echo "consolidated_into: ${consolidated}" >> /tmp/memory_temp.md
  fi

  # Close frontmatter
  echo "---" >> /tmp/memory_temp.md
  echo "" >> /tmp/memory_temp.md

  # Add content
  echo "$content" >> /tmp/memory_temp.md
  echo "" >> /tmp/memory_temp.md

  # Add context if present
  if [ -n "$context" ] && [ "$context" != "null" ]; then
    echo "**Context:** $context" >> /tmp/memory_temp.md
    echo "" >> /tmp/memory_temp.md
  fi

  # Add source
  if [ -n "$source_date" ] && [ "$source_date" != "null" ]; then
    echo "**Source:** $source_date - $source_context" >> /tmp/memory_temp.md
  fi

  # Preview
  echo -e "${YELLOW}Converting:${NC} $(basename "$json_file") → $(basename "$md_file")"

  if [ "$DRY_RUN" = false ]; then
    # Move JSON to .json backup
    mv "$json_file" "${json_file}.backup"

    # Write markdown
    mv /tmp/memory_temp.md "$md_file"

    echo -e "${GREEN}✓${NC} Migrated: $md_file"
    ((MIGRATED++))
  else
    echo -e "${GREEN}✓${NC} Would migrate: $md_file"
    ((MIGRATED++))
  fi
}

# Find all JSON memory files
echo "Scanning for JSON memories..."
echo ""

# Global preferences
if [ -d ~/.claude/neat_memory/preferences ]; then
  for json_file in ~/.claude/neat_memory/preferences/*.json; do
    [ -e "$json_file" ] || continue
    convert_json_to_md "$json_file"
  done
fi

# Global patterns
if [ -d ~/.claude/neat_memory/patterns ]; then
  for json_file in ~/.claude/neat_memory/patterns/*.json; do
    [ -e "$json_file" ] || continue
    convert_json_to_md "$json_file"
  done
fi

# Project solutions
if [ -d .claude/neat_memory/solutions ]; then
  for json_file in .claude/neat_memory/solutions/*.json; do
    [ -e "$json_file" ] || continue
    convert_json_to_md "$json_file"
  done
fi

# Project lessons
if [ -d .claude/neat_memory/lessons ]; then
  for json_file in .claude/neat_memory/lessons/*.json; do
    [ -e "$json_file" ] || continue
    convert_json_to_md "$json_file"
  done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Migrated:${NC} $MIGRATED"
echo -e "${RED}Errors:${NC} $ERRORS"
echo ""

if [ "$DRY_RUN" = false ]; then
  echo "Original JSON files backed up with .backup extension"
  echo "To restore: find ~/.claude/neat_memory -name '*.json.backup' -exec bash -c 'mv \"\$1\" \"\${1%.backup}\"' _ {} \;"
  echo ""
  echo "Next steps:"
  echo "1. Rebuild indexes: Run neat-memory-manager"
  echo "2. Test recall: /neat-memory-recall \"test query\""
  echo "3. If all works, delete backups: find ~/.claude/neat_memory -name '*.json.backup' -delete"
else
  echo "Run without --dry-run to perform migration"
fi
