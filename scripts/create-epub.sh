#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
manuscript_script="$script_dir/create-manuscript.sh"
manuscript_file="$repo_root/The End of Inside.md"
cover_file="$repo_root/cover.png"
output_file="$repo_root/The End of Inside.epub"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Required file not found: %s\n' "$1" >&2
    exit 1
  fi
}

require_command pandoc
require_file "$manuscript_script"
require_file "$cover_file"

bash "$manuscript_script"
require_file "$manuscript_file"

pandoc "$manuscript_file" \
  --from markdown \
  --to epub3 \
  --toc \
  --toc-depth=2 \
  --split-level=2 \
  --metadata title="The End of Inside" \
  --metadata author="Joshua Szepietowski" \
  --metadata lang="en-US" \
  --resource-path="$repo_root" \
  --epub-cover-image="$cover_file" \
  --output "$output_file"

printf 'Created %s\n' "$output_file"
