#!/bin/bash

[ $# -eq 0 ] && {
  echo "Usage: $0 <file>..." >&2
  exit 1
}

for file in "$@"; do
  [ ! -f "$file" ] && {
    echo "Skipping: $file" >&2
    continue
  }
  awk '{ sub(/\r$/,""); print }' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
  echo "Converted: $file"
done
