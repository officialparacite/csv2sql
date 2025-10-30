#!/usr/bin/awk -f

BEGIN {
  FPAT = "([^,]*)|(\"[^\"]*\")"
}

{
  for (i = 1; i <= NF; i++) {
    if (NR == 1) {
      header[i] = ($i != "" && $i !~ /^[ \t]*$/) ? $i : "column_" i
    }
    else {
      gsub(/^"|"$/, "", $i)

      if ($i == "") {
#        type = "EMPTY"
        nullable[i] = 1
        continue  # Don't count as a type
      }
      else if ($i ~ /^(true|false|t|f|yes|no|y|n)$/i) {
        type = "BOOLEAN"
      }
      else if ($i ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:?[0-9]{2}$/) {
        type = "TIMESTAMPTZ"
      }
      else if ($i ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/) { 
        type = "TIMESTAMP"
      }
      else if ($i ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
        type = "DATE"
      }
      else if ($i ~ /^-?[0-9]+\.[0-9]+$/) {
        type = "DECIMAL"
      }
      else if ($i ~ /^-?[0-9]+$/) {
        type = "INTEGER"
      }
#      else if ($i ~ /[a-zA-Z]/) {
      else if (length($i) > 0) {
        type = "VARCHAR"
        if (length($i) > max_len[i]) max_len[i] = length($i)
      }
      else {
        type = "UNKNOWN"
      }

      count[i, type]++

    }
    if (i > max_col) max_col = i
  }
}

END {
  # First pass: show analysis
  for (col = 1; col <= max_col; col++) {
    printf("\nColumn: %d \t\b\b(%s)\n", col, header[col])
 
    # Count how many different types this column has
    type_count = 0
    for (type in count) {
      split(type, parts, SUBSEP)
      if (parts[1] == col) {
        types[col, ++type_count] = parts[2]
        type_names[parts[2]] = parts[2]  # Store for lookup
        printf("  %-12s: %d\n", parts[2], count[type])
      }
    }
    col_type_count[col] = type_count
  }
 
  # Second pass: interactive decisions
  print "\n=== Type Selection ==="
  for (col = 1; col <= max_col; col++) {
    printf("\nColumn: %s\n", header[col])
 
    if (col_type_count[col] == 0) {           # ← ADD THIS
    # All NULL column
      final_type[col] = "VARCHAR(255)"
      printf("  All values NULL, defaulting to: VARCHAR(255)\n")
    }
    else if (col_type_count[col] == 1) {
      # Only one type, auto-select
      final_type[col] = types[col, 1]
      if (final_type[col] == "VARCHAR") {
        final_type[col] = "VARCHAR(" (max_len[col] ? max_len[col] : 255) ")"
      }
      printf("  Auto-selected: %s\n", final_type[col])
    }
    else {
      # Multiple types, prompt user
      printf("  Multiple types found. Choose:\n")
      for (i = 1; i <= col_type_count[col]; i++) {
        t = types[col, i]
        if (t == "VARCHAR" && max_len[col]) {
          printf("  [%d] %s(%d)\n", i, t, max_len[col])
        } 
        else {
          printf("  [%d] %s\n", i, t)
        }
      }
      printf("  Choice (1-%d): ", col_type_count[col])
 
      getline choice < "/dev/tty"
 
      if (choice >= 1 && choice <= col_type_count[col]) {
        final_type[col] = types[col, choice]
        if (final_type[col] == "VARCHAR") {
          final_type[col] = "VARCHAR(" (max_len[col] ? max_len[col] : 255) ")"
        }
      }
      else {
        # Default to VARCHAR on invalid input
        final_type[col] = "VARCHAR(" (max_len[col] ? max_len[col] : 255) ")"
        printf("  Invalid choice, defaulting to VARCHAR\n")
      }
    }
  }
 
  # Final schema output
  print "\n=== Final Schema ==="
  for (col = 1; col <= max_col; col++) {
    null_flag = nullable[col] ? "NULL" : "NOT NULL"
    printf("  %s: %s %s\n", header[col], final_type[col], null_flag)
  }
  # Write JSON metadata
  metadata_file = "schema.json"
  print "{" > metadata_file
  print "  \"columns\": [" > metadata_file
  for (col = 1; col <= max_col; col++) {
    null_flag = nullable[col] ? "true" : "false"
    comma = (col < max_col) ? "," : ""
 
  # Escape quotes in column names
    col_name = header[col]
    gsub(/"/, "\\\"", col_name)

    printf("    {\"name\": \"%s\", \"type\": \"%s\", \"nullable\": %s}%s\n", col_name, final_type[col], null_flag, comma) > metadata_file
  }
  print "  ]" > metadata_file
  print "}" > metadata_file
  close(metadata_file)
  print "\nMetadata written to: " metadata_file
}
