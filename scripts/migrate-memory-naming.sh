#!/usr/bin/env bash
# Migration script: Rename memory files from counter-based to slug-based naming
# Old: pref_001_title.json → New: pref_title.json

set -euo pipefail

GLOBAL_MEMORY="$HOME/.claude/neat_memory"

# Slugify function: extract slug from old filename
slugify_from_filename() {
    local filename="$1"
    # Extract slug part after counter: pref_001_tdd-skill-structure.json → tdd-skill-structure
    local slug=$(echo "$filename" | sed -E 's/^[a-z]+_[0-9]+_(.+)\.json$/\1/')
    # Convert hyphens to underscores
    slug=$(echo "$slug" | tr '-' '_')
    echo "$slug"
}

# Get prefix from filename
get_prefix() {
    local filename="$1"
    echo "$filename" | sed -E 's/^([a-z]+)_[0-9]+_.+\.json$/\1/'
}

# Update ID in JSON file
update_json_id() {
    local file="$1"
    local new_id="$2"

    # Read JSON, update id field, write back
    if command -v jq >/dev/null 2>&1; then
        # Use jq if available
        local tmp=$(mktemp)
        jq --arg new_id "$new_id" '.id = $new_id' "$file" > "$tmp"
        mv "$tmp" "$file"
    else
        # Fallback: sed (fragile but works for simple cases)
        sed -i.bak "s/\"id\": \"[^\"]*\"/\"id\": \"$new_id\"/" "$file"
        rm -f "${file}.bak"
    fi
}

# Migrate files in a directory
migrate_directory() {
    local dir="$1"
    local type_name="$2"

    echo "Migrating $type_name in $dir..."

    if [ ! -d "$dir" ]; then
        echo "  Directory does not exist, skipping"
        return
    fi

    local count=0
    for old_file in "$dir"/*_[0-9][0-9][0-9]_*.json; do
        [ -f "$old_file" ] || continue

        local basename=$(basename "$old_file")
        local prefix=$(get_prefix "$basename")
        local slug=$(slugify_from_filename "$basename")
        local new_filename="${prefix}_${slug}.json"
        local new_file="$dir/$new_filename"
        local new_id="${prefix}_${slug}"

        echo "  $basename → $new_filename"

        # Update ID in JSON content
        update_json_id "$old_file" "$new_id"

        # Rename file
        mv "$old_file" "$new_file"

        ((count++))
    done

    echo "  Migrated $count files"
}

# Update index.json
update_index() {
    local index_file="$GLOBAL_MEMORY/.index/index.json"

    if [ ! -f "$index_file" ]; then
        echo "Index file not found, skipping"
        return
    fi

    echo "Updating index.json..."

    if command -v jq >/dev/null 2>&1; then
        # Rebuild index from actual files
        local tmp=$(mktemp)
        echo "{}" > "$tmp"

        for type_dir in "$GLOBAL_MEMORY"/{preferences,patterns,solutions,lessons}; do
            [ -d "$type_dir" ] || continue

            for memory_file in "$type_dir"/*.json; do
                [ -f "$memory_file" ] || continue

                local id=$(jq -r '.id' "$memory_file")
                local title=$(jq -r '.title' "$memory_file")
                local type=$(jq -r '.type' "$memory_file")
                local tags=$(jq -r '.tags' "$memory_file")
                local file_path=$(echo "$memory_file" | sed "s|$GLOBAL_MEMORY/||")

                jq --arg id "$id" \
                   --arg title "$title" \
                   --arg type "$type" \
                   --argjson tags "$tags" \
                   --arg file_path "$file_path" \
                   '.[$id] = {title: $title, type: $type, tags: $tags, file_path: $file_path}' \
                   "$tmp" > "${tmp}.new"
                mv "${tmp}.new" "$tmp"
            done
        done

        mv "$tmp" "$index_file"
        echo "  Index rebuilt with $(jq 'length' "$index_file") entries"
    else
        echo "  WARNING: jq not available, skipping index update"
        echo "  Please manually rebuild index.json"
    fi
}

# Delete counters.json
delete_counters() {
    local counters_file="$GLOBAL_MEMORY/.index/counters.json"

    if [ -f "$counters_file" ]; then
        echo "Removing counters.json..."
        rm "$counters_file"
        echo "  Deleted"
    else
        echo "counters.json not found (already removed)"
    fi
}

# Main execution
main() {
    echo "=== NEAT Memory Migration: Counter-based → Slug-based Naming ==="
    echo

    if [ ! -d "$GLOBAL_MEMORY" ]; then
        echo "No global memory directory found at $GLOBAL_MEMORY"
        echo "Nothing to migrate."
        exit 0
    fi

    echo "Global memory directory: $GLOBAL_MEMORY"
    echo

    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        echo "WARNING: jq not found. Install with: brew install jq"
        echo "Migration will continue but index update may be incomplete."
        echo
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Backup first
    local backup_dir="${GLOBAL_MEMORY}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup at $backup_dir..."
    cp -R "$GLOBAL_MEMORY" "$backup_dir"
    echo "  Backup created"
    echo

    # Migrate each type
    migrate_directory "$GLOBAL_MEMORY/preferences" "preferences"
    migrate_directory "$GLOBAL_MEMORY/patterns" "patterns"
    migrate_directory "$GLOBAL_MEMORY/solutions" "solutions"
    migrate_directory "$GLOBAL_MEMORY/lessons" "lessons"
    echo

    # Update index
    update_index
    echo

    # Delete counters.json
    delete_counters
    echo

    echo "=== Migration Complete ==="
    echo
    echo "Backup saved to: $backup_dir"
    echo "If everything looks good, you can delete the backup with:"
    echo "  rm -rf '$backup_dir'"
}

main "$@"
