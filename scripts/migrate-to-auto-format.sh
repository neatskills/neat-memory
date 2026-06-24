#!/bin/bash
# Don't exit on error in loops
set +e

# Migrate neat-memory to auto-memory compatible format
# Usage: ./scripts/migrate-to-auto-format.sh [--dry-run]

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
NC='\033[0m'

# Counters
MIGRATED=0
ERRORS=0

# Type mappings
map_type() {
  local neat_type="$1"
  case "$neat_type" in
    preference) echo "feedback" ;;
    pattern) echo "feedback" ;;
    solution) echo "project" ;;
    lesson) echo "project" ;;
    *) echo "feedback" ;;
  esac
}

# Convert filename: snake_case → kebab-case
to_kebab_case() {
  echo "$1" | sed 's/_/-/g'
}

# Convert markdown file
convert_md_to_auto_format() {
  local md_file="$1"
  local dir=$(dirname "$md_file")
  local filename=$(basename "$md_file")

  # Extract current frontmatter
  if ! frontmatter=$(sed -n '/^---$/,/^---$/p' "$md_file" | sed '1d;$d'); then
    echo -e "${RED}✗${NC} Failed to parse frontmatter: $md_file"
    ((ERRORS++))
    return 1
  fi

  # Extract fields
  name=$(echo "$frontmatter" | grep "^name:" | sed 's/name: *//')
  type_field=$(echo "$frontmatter" | grep "^type:" | sed 's/type: *//')
  title=$(echo "$frontmatter" | grep "^title:" | sed 's/title: *//')
  created=$(echo "$frontmatter" | grep "^created:" | sed 's/created: *//')
  promoted=$(echo "$frontmatter" | grep "^promoted:" | sed 's/promoted: *//')

  # Extract arrays (tags, intent_triggers)
  tags=$(sed -n '/^tags:/,/^]/p' "$md_file" | tr '\n' ' ' | sed 's/tags: *//' | tr -d '\n')
  triggers=$(sed -n '/^intent_triggers:/,/^]/p' "$md_file" | tr '\n' ' ' | sed 's/intent_triggers: *//' | tr -d '\n')

  # Extract body (everything after second ---), preserving newlines
  body=$(awk '/^---$/{f++; next} f==2' "$md_file")

  # Generate description from title + first sentence of body
  first_sentence=$(echo "$body" | grep -v '^$' | head -1 | sed 's/\*\*//g' | cut -d'.' -f1)
  if [ -z "$first_sentence" ]; then
    description="$title"
  else
    description="$first_sentence"
  fi

  # Map type
  auto_type=$(map_type "$type_field")

  # Convert name to kebab-case
  kebab_name=$(to_kebab_case "$name")
  new_filename="${kebab_name}.md"
  new_file="${dir}/${new_filename}"

  # Preview
  echo -e "${YELLOW}Converting:${NC} $filename → $new_filename (snake_case → kebab-case)"

  if [ "$DRY_RUN" = false ]; then
    # Build new frontmatter
    cat > /tmp/memory_temp.md <<EOF
---
name: ${kebab_name}
description: ${description}
metadata:
  type: ${auto_type}
  neat_type: ${type_field}
  tags: ${tags}
  intent_triggers: ${triggers}
  created: ${created}
  promoted: ${promoted:-false}
---

${body}
EOF

    # Backup original
    mv "$md_file" "${md_file}.backup"

    # Write new format
    mv /tmp/memory_temp.md "$new_file"

    echo -e "${GREEN}✓${NC} Migrated: $new_file"
    ((MIGRATED++))
  else
    echo -e "${GREEN}✓${NC} Would migrate: $new_file"
    ((MIGRATED++))
  fi
}

# Find all markdown memory files
echo "Scanning for markdown memories..."
echo ""

# Global preferences
if [ -d ~/.claude/neat_memory/preferences ]; then
  for md_file in ~/.claude/neat_memory/preferences/*.md; do
    [ -e "$md_file" ] || continue
    convert_md_to_auto_format "$md_file"
  done
fi

# Global patterns
if [ -d ~/.claude/neat_memory/patterns ]; then
  for md_file in ~/.claude/neat_memory/patterns/*.md; do
    [ -e "$md_file" ] || continue
    convert_md_to_auto_format "$md_file"
  done
fi

# Project solutions
if [ -d .claude/neat_memory/solutions ]; then
  for md_file in .claude/neat_memory/solutions/*.md; do
    [ -e "$md_file" ] || continue
    convert_md_to_auto_format "$md_file"
  done
fi

# Project lessons
if [ -d .claude/neat_memory/lessons ]; then
  for md_file in .claude/neat_memory/lessons/*.md; do
    [ -e "$md_file" ] || continue
    convert_md_to_auto_format "$md_file"
  done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Migrated:${NC} $MIGRATED"
echo -e "${RED}Errors:${NC} $ERRORS"
echo ""

if [ "$DRY_RUN" = false ]; then
  echo "Original markdown files backed up with .backup extension"
  echo "To restore: find ~/.claude/neat_memory -name '*.md.backup' -exec bash -c 'mv \"\$1\" \"\${1%.backup}\"' _ {} \;"
  echo ""
  echo "Next steps:"
  echo "1. Rebuild indexes: ./scripts/rebuild-index.sh"
  echo "2. Test recall: /neat-memory-recall \"test query\""
  echo "3. If all works, delete backups: find ~/.claude/neat_memory -name '*.backup' -delete"
else
  echo "Run without --dry-run to perform migration"
fi
