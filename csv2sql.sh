#!/bin/bash

if (($# < 2)); then
  echo "Usage: $0 <CSV_FILE> <TABLE_NAME> [OUTPUT_FILE]" >&2
  exit 1
fi

file_name="$1"
table_name="$2"
output_file="${3:-output.sql}"

if [[ ! -f "$file_name" ]]; then
  echo "Error: File '$file_name' not found" >&2
  exit 1
fi

echo "Creating backup and converting line endings..."
cp "$file_name" "x_$file_name"
./dos2unix_awk_clone.sh "x_$file_name"

echo "Analyzing CSV and inferring schema..."
echo "(You may be prompted to select types for columns with mixed data)"
./parse.awk "x_$file_name"

echo "Cleaning schema JSON..."
./schema_fix.sh

echo "Generating SQL..."
./generate.awk "x_$file_name" "$table_name" >"$output_file"

echo "Done! SQL written to: $output_file"
