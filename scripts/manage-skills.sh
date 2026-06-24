#!/usr/bin/env bash
set -euo pipefail

mode="${1:-install}"
if [ "$mode" != "install" ] && [ "$mode" != "uninstall" ]; then
  echo "Usage: $0 [install|uninstall]" >&2
  echo "  Default: install" >&2
  exit 1
fi

SKILL_PREFIX="neat-memory-"
root="$(cd "$(dirname "$0")/.." && pwd)"
dst="$HOME/.claude/skills"

# Check if symlink points to this project's skill directory
is_managed_symlink() {
  local target_path="$1"
  local source_path="$2"
  [ -L "$target_path" ] && [ "$(realpath "$target_path" 2>/dev/null)" = "$(realpath "$source_path")" ]
}

if [ "$mode" = "install" ]; then
  mkdir -p "$dst"
fi

for src in "$root"/${SKILL_PREFIX}*; do
  [ -d "$src" ] || continue
  [ -f "$src/SKILL.md" ] || continue

  name=$(grep '^name:' "$src/SKILL.md" | head -1 | sed 's/^name: *//')
  if [ -z "$name" ]; then
    echo "ERROR: no name in $src/SKILL.md frontmatter" >&2
    continue
  fi

  if [ "$mode" = "install" ]; then
    if is_managed_symlink "$dst/$name" "$src"; then
      echo "INFO: $name already installed — skipping"
      continue
    elif [ -e "$dst/$name" ]; then
      echo "WARN: $dst/$name already exists — skipping"
      continue
    fi

    ln -s "$src" "$dst/$name" && echo "INFO: $name installed"

  else  # uninstall
    if is_managed_symlink "$dst/$name" "$src"; then
      rm "$dst/$name" && echo "INFO: $name uninstalled"
    elif [ -e "$dst/$name" ]; then
      echo "WARN: $name exists but was not installed by this project — skipping"
    else
      echo "INFO: $name not installed — skipping"
    fi
  fi
done

# Clean up empty directory after uninstall
if [ "$mode" = "uninstall" ] && [ -d "$dst" ] && [ -z "$(ls -A "$dst")" ]; then
  rmdir "$dst" && echo "INFO: Removed empty directory $dst"
fi
