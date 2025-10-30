#!/bin/bash

[ $# -eq 0 ] && {
  echo "Usage: $0 <file>..." >&2
  exit 1
}

awk '{
  # Remove control characters
  gsub(/[\x00-\x1F\x7F]/, "", $0)
  print
}' $1 >schema_clean.json
