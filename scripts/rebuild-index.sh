#!/bin/bash
set -e

# Rebuild .index/index.json from markdown files
# Reads YAML frontmatter from each .md file

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

rebuild_index() {
  local base_dir="$1"
  local index_file="${base_dir}/.index/index.json"

  echo -e "${YELLOW}Rebuilding index:${NC} $base_dir"

  # Create .index directory if missing
  mkdir -p "${base_dir}/.index"

  # Start JSON structure
  cat > "$index_file" <<'EOF'
{
  "preferences": [],
  "patterns": [],
  "solutions": [],
  "lessons": []
}
EOF

  # Function to extract frontmatter field
  extract_field() {
    local file="$1"
    local field="$2"
    # Extract between --- markers, get field value
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${field}:" | sed "s/^${field}: *//" | sed 's/^"\(.*\)"$/\1/'
  }

  # Function to extract nested metadata field
  extract_metadata_field() {
    local file="$1"
    local field="$2"
    # Extract from metadata section
    sed -n '/^metadata:/,/^[a-z]/{/^  '"$field"':/p}' "$file" | sed 's/^  '"$field"': *//'
  }

  # Process each type
  for type in preferences patterns solutions lessons; do
    type_dir="${base_dir}/${type}"
    [ -d "$type_dir" ] || continue

    for md_file in "$type_dir"/*.md; do
      [ -e "$md_file" ] || continue

      filename=$(basename "$md_file")

      # Extract frontmatter fields
      name=$(extract_field "$md_file" "name")
      description=$(extract_field "$md_file" "description")

      # Extract from metadata using grep
      created=$(grep '  created:' "$md_file" | sed 's/.*created: *//')

      # Extract arrays - get the line, remove brackets and quotes, then rejoin
      tags=$(grep '  tags:' "$md_file" | sed 's/.*tags: *//' | tr -d '[]"' | sed 's/, */", "/g' | sed 's/^  *//' | sed 's/  *$//' | sed 's/^/"/' | sed 's/$/"/')
      triggers=$(grep '  intent_triggers:' "$md_file" | sed 's/.*intent_triggers: *//' | tr -d '[]"' | sed 's/, */", "/g' | sed 's/^  *//' | sed 's/  *$//' | sed 's/^/"/' | sed 's/$/"/')

      # Build entry
      entry=$(cat <<EOF
    {
      "file": "${filename}",
      "name": "${name}",
      "description": "${description}",
      "tags": [${tags}],
      "triggers": [${triggers}],
      "created": "${created}"
    }
EOF
)

      # Add to index using jq
      tmp_index="${index_file}.tmp"
      jq ".${type} += [${entry}]" "$index_file" > "$tmp_index"
      mv "$tmp_index" "$index_file"

      echo -e "  ${GREEN}✓${NC} Added: $filename"
    done
  done

  echo -e "${GREEN}✓${NC} Index rebuilt: $index_file"
  echo ""
}

# Rebuild global index
if [ -d ~/.claude/neat_memory ]; then
  rebuild_index ~/.claude/neat_memory
fi

# Rebuild project index
if [ -d .claude/neat_memory ]; then
  rebuild_index .claude/neat_memory
fi

echo "Done!"
