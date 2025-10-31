#!/bin/bash

input_file="${1:-schema.json}"

if [[ ! -f "$input_file" ]]; then
  echo "Error: File '$input_file' not found" >&2
  echo "Usage: $0 [file]  (defaults to schema.json)" >&2
  exit 1
fi

awk '{
  gsub(/[\x00-\x1F\x7F]/, "", $0)
  print
}' "$input_file" >schema_clean.json

echo "Cleaned schema written to: schema_clean.json"
