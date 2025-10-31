# CSV to SQL Converter

A blazingly fast AWK-based toolkit for converting CSV files to SQL statements with automatic type inference.

## Quick Start

```bash
# 1. Make a backup and convert line endings
cp original.csv original_unix.csv
./dos2unix_awk_clone.sh original_unix.csv

# 2. Analyze CSV and infer schema
./parse.awk original_unix.csv

# 3. Clean the schema JSON
./schema_fix.sh schema.json

# 4. Generate SQL
./generate.awk original_unix.csv my_table > output.sql
```

## What it does:

- Creates a Unix-compatible file
- Scans all rows and infers data types
- Detects nullable columns
- Shows type distribution for each column
- Prompts you to choose when multiple types are detected

**Example output:**
```
Column: 1 	(TaskID)
  INTEGER     : 1000

Column: 2 	(Status)
  VARCHAR     : 800
  INTEGER     : 200

=== Type Selection ===

Column: Status
  Multiple types found. Choose:
  [1] VARCHAR(11)
  [2] INTEGER
  Choice (1-2): 1

Auto-selected: VARCHAR(11)
```

**Output:** `schema.json`

The schema is saved as JSON, so you can manually edit types without re-running the parser (Optional)

```json
{
  "columns": [
    {"name": "TaskID", "type": "INTEGER", "nullable": false},
    {"name": "Title", "type": "VARCHAR(100)", "nullable": false},
    {"name": "DueDate", "type": "DATE", "nullable": true}
  ]
}
```

Clean the Schema:

```bash
./schema_fix.sh schema.json
```

**Output:** `schema_clean.json`

This step validates and formats the JSON for the SQL generator.

Finally Generate SQL:

```bash
./generate.awk data_unix.csv my_table_name > output.sql
```

**Output:**
```sql
CREATE TABLE my_table_name (
  TaskID INTEGER NOT NULL,
  Title VARCHAR(100) NOT NULL,
  DueDate DATE NULL
);

INSERT INTO my_table_name (TaskID, Title, DueDate) VALUES (1, 'Login page redesign', '2024-02-01');
INSERT INTO my_table_name (TaskID, Title, DueDate) VALUES (2, 'Fix navigation bug', NULL);
```

## Supported databases (will add more databases later)

- Amazon Redshift

## Limitations

- Won't handle **escaped quotes** inside quoted fields (e.g., `"He said ""hello"""`)
- Won't handle **newlines inside quoted fields** (multi-line cells)
- Expects **comma-separated** values (not tab or semicolon)

## Best for

- Clean, well-formatted CSVs
- Large datasets (millions of rows)
- Standard CSV exports from tools like Excel, Google Sheets, or databases

## Troubleshooting

### Script hangs or produces garbage output

**Cause:** Windows line endings (`\r\n`)  
**Fix:** Run `dos2unix_awk_clone.sh` first

```bash
./dos2unix_awk_clone.sh your_file.csv
```

### Wrong data types detected

**Cause:** Mixed data in columns
**Fix:** Re-run `parse.awk` and choose the correct type, or manually edit `schema.json`

### Missing `schema_clean.json` error

**Cause:** Skipped schema cleaning step
**Fix:** Run `./schema_fix.sh` before generating SQL

### Quotes not escaped properly

**Cause:** Single quotes in data (e.g., `O'Brien`)  
**Status:** Script automatically escapes these as `O''Brien`

## Examples

### Example 1: Simple CSV

**Input:** `users.csv`
```csv
id,name,age
1,Alice,30
2,Bob,25
```

**Commands:**
```bash
cp users.csv users_unix.csv
./dos2unix_awk_clone.sh users_unix.csv
./parse.awk users_unix.csv
./schema_fix.sh
./generate.awk users_unix.csv users > users.sql
```

**Output:** `users.sql`
```sql
CREATE TABLE users (
  id INTEGER NOT NULL,
  name VARCHAR(5) NOT NULL,
  age INTEGER NOT NULL
);

INSERT INTO users (id, name, age) VALUES (1, 'Alice', 30);
INSERT INTO users (id, name, age) VALUES (2, 'Bob', 25);
```

### Example 2: With NULL values

**Input:** `products.csv`
```csv
id,name,price
1,Widget,19.99
2,Gadget,
3,Doohickey,29.99
```

**Output:**
```sql
CREATE TABLE products (
  id INTEGER NOT NULL,
  name VARCHAR(10) NOT NULL,
  price DECIMAL(10,2) NULL
);

INSERT INTO products (id, name, price) VALUES (1, 'Widget', 19.99);
INSERT INTO products (id, name, price) VALUES (2, 'Gadget', NULL);
INSERT INTO products (id, name, price) VALUES (3, 'Doohickey', 29.99);
```

## Contributing

Contributions welcome! Please test with various CSV formats and edge cases.

---

**Note:** Always backup your original CSV before processing!
