#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
chapters_dir="$repo_root/chapters"
output_file="$repo_root/The End of Inside.md"
tmp_output="$(mktemp "${TMPDIR:-/tmp}/the-end-of-inside.XXXXXX")"

cleanup() {
  rm -f "$tmp_output"
}

trap cleanup EXIT

if [[ ! -d "$chapters_dir" ]]; then
  echo "Chapters directory not found: $chapters_dir" >&2
  exit 1
fi

printf '# The End of Inside\n\nA Novel by Joshua Szepietowski\n' > "$tmp_output"

found_chapters=0

while IFS= read -r act_dir; do
  [[ -n "$act_dir" ]] || continue

  act_title="$(basename "$act_dir")"
  printf '\n## %s\n' "$act_title" >> "$tmp_output"

  while IFS= read -r chapter_file; do
    [[ -n "$chapter_file" ]] || continue

    found_chapters=1
    chapter_heading="$(head -n 1 "$chapter_file")"

    if [[ "$chapter_heading" == \#\ * ]]; then
      chapter_title="${chapter_heading#\# }"
      chapter_body="$(awk 'NR == 1 { next } NR == 2 && $0 == "" { next } { print }' "$chapter_file")"
    else
      chapter_title="$(basename "$chapter_file" .md)"
      chapter_body="$(cat "$chapter_file")"
    fi

    printf '\n### %s\n\n%s\n' "$chapter_title" "$chapter_body" >> "$tmp_output"
  done < <(find "$act_dir" -mindepth 1 -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort)
done < <(find "$chapters_dir" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)

if [[ "$found_chapters" -eq 0 ]]; then
  echo "No chapter files found in $chapters_dir" >&2
  exit 1
fi

printf '\n' >> "$tmp_output"
mv "$tmp_output" "$output_file"

echo "Created $output_file"