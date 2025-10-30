#!/usr/bin/awk -f

BEGIN {
  if (ARGC < 3) {
    print "Usage: ./csv_to_sql.awk <csv_file> <table_name>" > "/dev/stderr"
    exit 1
  }

  csv_file = ARGV[1]
  table_name = ARGV[2]
  ARGV[1] = csv_file
  ARGV[2] = ""

  FPAT = "([^,]*)|(\"[^\"]*\")"

  # Check if schema_clean.json exists
  schema_file = "schema_clean.json"
  if ((getline test_line < schema_file) < 0) {
    print "ERROR: Cannot find schema_clean.json in current directory" > "/dev/stderr"
    exit 1
  }
  close(schema_file)

  # Read schema_clean.json
  while ((getline line < schema_file) > 0) {
    if (line ~ /"name":/) {
      match(line, /"name": "([^"]*)"/, arr)
      cols[++col_count] = arr[1]
    }
    if (line ~ /"type":/) {
      match(line, /"type": "([^"]*)"/, arr)
      types[col_count] = arr[1]
    }
    if (line ~ /"nullable":/) {
      match(line, /"nullable": (true|false)/, arr)
      nullable[col_count] = (arr[1] == "true")
    }
  }
  close(schema_file)

  if (col_count == 0) {
    print "ERROR: schema_clean.json appears to be empty or invalid" > "/dev/stderr"
    exit 1
  }

  # Generate CREATE TABLE
  printf("CREATE TABLE %s (\n", table_name)
  for (i = 1; i <= col_count; i++) {
    sql_type = map_to_sql_type(types[i])
    null_clause = nullable[i] ? "NULL" : "NOT NULL"
    comma = (i < col_count) ? "," : ""
    printf("  %s %s %s%s\n", cols[i], sql_type, null_clause, comma)
  }
  print ");\n"
}

FNR == 1 { next }  # Skip header

{
  printf("INSERT INTO %s (", table_name)
  for (i = 1; i <= col_count; i++) {
    printf("%s%s", cols[i], (i < col_count) ? ", " : "")
  }
  printf(") VALUES (")

  # Determine how many columns we actually have
  max_cols = (NF < col_count) ? NF : col_count
  
  for (i = 1; i <= max_cols; i++) {
    val = $i
    gsub(/^"|"$/, "", val)

    if (val == "") {
      printf("NULL")
    }
    else if (types[i] ~ /VARCHAR/) {
      gsub(/'/, "''", val)
      printf("'%s'", val)
    }
    else if (types[i] == "BOOLEAN") {
      printf("%s", toupper(val))
    }
    else if (types[i] ~ /TIMESTAMP|DATE/) {
      printf("'%s'", val)
    }
    else {
      printf("%s", val)
    }

    if (i < max_cols) printf(", ")
  }
  
  # Fill in NULLs for missing columns
  for (i = max_cols + 1; i <= col_count; i++) {
    printf(", NULL")
  }
  
  print ");"
}

function map_to_sql_type(type) {
  if (type ~ /^VARCHAR/)
    return type
  else if (type == "INTEGER")
    return "INTEGER"
  else if (type == "DECIMAL")
    return "DECIMAL(10,2)"
  else if (type == "BOOLEAN")
    return "BOOLEAN"
  else if (type == "DATE")
    return "DATE"
  else if (type == "TIMESTAMP")
    return "TIMESTAMP"
  else if (type == "TIMESTAMPTZ")
    return "TIMESTAMPTZ"
  else
    return "TEXT"
}
