---
name: db-query
description: "Database query and analysis support. Creates, executes, and analyzes SQL queries. Supports BigQuery, PostgreSQL, MySQL. Triggers: /db-query, SQL, query, data analysis, BigQuery"
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
model: sonnet
context: fork
---

# Database Query & Analysis Skill

Supports SQL query creation, execution, and result analysis.

## Supported Databases

| DB | CLI Tool | Connection Method |
|----|----------|-------------------|
| BigQuery | `bq` | `bq query --use_legacy_sql=false` |
| PostgreSQL | `psql` | `psql -h host -U user -d db` |
| MySQL | `mysql` | `mysql -h host -u user -p db` |
| SQLite | `sqlite3` | `sqlite3 file.db` |

## Features

### 1. Query Creation Support

Generate SQL from natural language:

```
User: "Daily active users for last month"

Generated SQL:
SELECT
  DATE(created_at) AS date,
  COUNT(DISTINCT user_id) AS active_users
FROM events
WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)
  AND event_type = 'login'
GROUP BY date
ORDER BY date;
```

### 2. Query Execution

```bash
# BigQuery
bq query --use_legacy_sql=false --format=prettyjson '
SELECT ...
'

# PostgreSQL
psql -c "SELECT ..." -h $DB_HOST -U $DB_USER -d $DB_NAME

# MySQL
mysql -e "SELECT ..." -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME
```

### 3. Result Analysis

```markdown
## Query Result Analysis

### Data Summary
- **Rows**: 1,234
- **Period**: 2025-01-01 to 2025-01-31

### Key Findings
1. Spike on 1/15 (+150% from previous day)
2. Weekends are about 60% of weekdays
3. Average: 1,000 users/day

### Visualization
| Date | Users | Trend |
|------|-------|-------|
| 1/1  | 500   | ▂ |
| 1/2  | 800   | ▅ |
| 1/15 | 2000  | █ |
```

## Query Pattern Collection

### User Analysis

```sql
-- DAU/WAU/MAU
SELECT
  COUNT(DISTINCT CASE WHEN DATE(ts) = CURRENT_DATE() THEN user_id END) AS dau,
  COUNT(DISTINCT CASE WHEN ts >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN user_id END) AS wau,
  COUNT(DISTINCT CASE WHEN ts >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN user_id END) AS mau
FROM events;

-- Retention
WITH cohort AS (
  SELECT
    user_id,
    DATE(MIN(created_at)) AS cohort_date
  FROM users
  GROUP BY user_id
)
SELECT
  cohort_date,
  COUNT(DISTINCT c.user_id) AS cohort_size,
  COUNT(DISTINCT CASE WHEN DATE(e.ts) = DATE_ADD(cohort_date, INTERVAL 7 DAY) THEN c.user_id END) AS day7_retained
FROM cohort c
LEFT JOIN events e ON c.user_id = e.user_id
GROUP BY cohort_date;
```

### Performance Analysis

```sql
-- Slow queries (PostgreSQL)
SELECT
  query,
  calls,
  total_time / 1000 AS total_seconds,
  mean_time / 1000 AS mean_seconds
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC
LIMIT 10;
```

### Error Analysis

```sql
-- Error frequency
SELECT
  error_code,
  error_message,
  COUNT(*) AS count,
  MIN(ts) AS first_seen,
  MAX(ts) AS last_seen
FROM error_logs
WHERE ts >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY error_code, error_message
ORDER BY count DESC;
```

## Output Format

```markdown
## Query Execution Result

### Query
```sql
SELECT ...
```

### Execution Info
- **Database**: BigQuery / production
- **Execution Time**: 2.3s
- **Scan Size**: 1.2 GB
- **Result Rows**: 1,234

### Results

| date | active_users | change |
|------|--------------|--------|
| 2025-01-01 | 1,000 | - |
| 2025-01-02 | 1,200 | +20% |
| 2025-01-03 | 950 | -21% |

### Analysis

**Trend**:
- Overall flat
- Decreasing trend on weekends

**Anomalies**:
- Spike on 1/15 (event impact?)

**Recommended Actions**:
1. Investigate cause of 1/15 spike
2. Consider weekend campaigns
```

## Security Considerations

### Required Rules

- **Execute SELECT only**: NEVER execute DELETE, UPDATE, DROP, INSERT, TRUNCATE, ALTER
- **Avoid direct production DB connection**: Use replicas when possible
- **Handle results carefully**: Be careful with personal information
- **Query logs**: Assume all executed queries are logged

### Safe Query Execution

```bash
# PostgreSQL: Use read-only transaction
psql -c "SET TRANSACTION READ ONLY; SELECT ..." -h $DB_HOST -U $DB_USER -d $DB_NAME

# MySQL: Read-only flag
mysql --safe-updates -e "SELECT ..." -h $DB_HOST -u $DB_USER $DB_NAME

# BigQuery: Dry run for pre-check
bq query --dry_run --use_legacy_sql=false 'SELECT ...'
```

### Prohibited Pattern Detection

Validate query before execution, **refuse execution** if contains:

- `DELETE`, `UPDATE`, `INSERT`, `DROP`, `TRUNCATE`, `ALTER`, `CREATE`
- `; --` (SQL injection pattern)
- `GRANT`, `REVOKE` (permission operations)

## BigQuery Specific

```bash
# List tables
bq ls project:dataset

# Check schema
bq show --schema project:dataset.table

# Execute query (dry run)
bq query --dry_run --use_legacy_sql=false 'SELECT ...'

# Save results to table
bq query --destination_table=project:dataset.result 'SELECT ...'
```

## Usage

```bash
# Create query from natural language
/db-query show daily DAU for last month

# Execute SQL directly
/db-query --execute "SELECT COUNT(*) FROM users"

# Check schema
/db-query --schema users
```
