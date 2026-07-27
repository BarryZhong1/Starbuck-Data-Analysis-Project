# Presentation Methods Implemented

The supplied presentation teaches MySQL stored procedures, procedure
parameters, three loop forms, and conditional logic. SQLite intentionally does
not implement stored procedures, so the project now has two complementary
layers:

- the existing SQLite pipeline performs reproducible cleaning, validation,
  auditing, and portable analysis; and
- the MySQL 8 layer imports only the generated clean tables and implements the
  presentation's stored-program features.

Neither layer updates the three raw CSV files.

## One-to-one feature map

| Presentation topic | Project implementation | Purpose |
|---|---|---|
| Stored procedure with no parameters | `sp_get_all_events()` | Returns all deduplicated events |
| One `IN` variable | `sp_gender_percentage_by_age(p_min_age)` | Calculates the gender mix at or above an age threshold |
| Multiple `IN` variables | `sp_gender_age_percentage(p_gender_code, p_min_age)` | Calculates one gender's share above an age threshold |
| `OUT` variable | `sp_event_count(p_event_type, p_event_count)` | Returns the deduplicated count for an event type |
| `INOUT` variable | `sp_customer_count_at_or_above_age(p_age_or_count)` | Accepts an age and replaces it with the matching customer count |
| `WHILE` loop | `sp_age_band_summary_while(p_start_age, p_end_age, p_step)` | Builds a parameterized age-band summary |
| `REPEAT` loop | `sp_offer_metrics_repeat()` | Builds one metrics row for each offer type |
| Plain `LOOP` | `sp_even_numbers_loop(p_max_value)` | Demonstrates `LOOP`, `LEAVE`, `ITERATE`, and `MOD` |
| `IF / ELSEIF / ELSE` | `sp_customer_income_band(p_customer_id)` | Assigns a transparent income band using non-imputed income |

The implementations are in
`mysql/init/03_stored_procedures.sql`. Parameter validation uses `SIGNAL`
instead of silently accepting impossible ages, unknown event types, or invalid
gender codes.

## Run the MySQL layer

Requirements: Docker Desktop or another Docker Compose-compatible runtime.

From the project root:

```bash
cp mysql/.env.example mysql/.env
# Replace the placeholder local passwords in mysql/.env.

docker compose --env-file mysql/.env \
  -f mysql/docker-compose.yml up -d --wait
```

The first startup:

1. creates a MySQL 8 database named `starbucks_analytics`;
2. creates constrained clean tables;
3. imports the clean CSV outputs from the SQLite pipeline;
4. recreates the analytical window-function views in MySQL; and
5. installs all nine stored procedures.

The raw files under `data/raw/` are not mounted into MySQL and cannot be changed
by these procedures.

Run the smoke tests:

```bash
docker compose --env-file mysql/.env \
  -f mysql/docker-compose.yml exec -T mysql \
  sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  < mysql/tests/smoke_test.sql
```

Connect interactively:

```bash
docker compose --env-file mysql/.env \
  -f mysql/docker-compose.yml exec mysql \
  sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'
```

MySQL is also exposed on local port `3307` for MySQL Workbench:

| Setting | Value |
|---|---|
| Host | `127.0.0.1` |
| Port | `3307` |
| Schema | `starbucks_analytics` |
| Username | Value of `MYSQL_USER` in `mysql/.env` |
| Password | Value of `MYSQL_PASSWORD` in `mysql/.env` |

The local `.env` file is excluded from Git.

## Call examples

### No parameters

```sql
CALL sp_get_all_events();
```

This intentionally returns a large result. The smoke test checks that the
procedure exists but does not call it.

### One `IN` parameter

```sql
CALL sp_gender_percentage_by_age(60);
```

Expected result from the supplied data:

| Gender | Customers | All customers age 60+ | Percentage |
|---|---:|---:|---:|
| F | 2,801 | 5,875 | 47.68% |
| M | 2,997 | 5,875 | 51.01% |
| O | 77 | 5,875 | 1.31% |

### Multiple `IN` parameters

```sql
CALL sp_gender_age_percentage('F', 30);
```

The parameter order matters. Calling the procedure with only one argument
correctly produces an argument-count error, which is the error demonstrated in
the presentation.

### `OUT` parameter

```sql
CALL sp_event_count('offer completed', @event_count);
SELECT @event_count;
```

Expected deduplicated count: `33182`.

### `INOUT` parameter

```sql
SET @age_or_count = 30;
CALL sp_customer_count_at_or_above_age(@age_or_count);
SELECT @age_or_count;
```

The value begins as the age threshold `30` and becomes the customer count
`13251`. This mirrors the presentation's INOUT behavior. In production code,
separate `IN` and `OUT` parameters are usually clearer when the input and output
represent different concepts.

### `WHILE`

```sql
CALL sp_age_band_summary_while(20, 89, 10);
```

The procedure repeatedly inserts one inclusive age interval until the ending
age is reached.

### `REPEAT`

```sql
CALL sp_offer_metrics_repeat();
```

`REPEAT` runs its body before checking the stopping condition. It returns:

| Offer type | Offers | Average difficulty | Average reward |
|---|---:|---:|---:|
| bogo | 4 | 7.50 | 7.50 |
| discount | 4 | 11.75 | 3.00 |
| informational | 2 | 0.00 | 0.00 |

### Plain `LOOP`

```sql
CALL sp_even_numbers_loop(10);
```

The procedure uses `ITERATE` to skip odd values, `MOD` to identify parity, and
`LEAVE` to stop. It returns `2, 4, 6, 8, 10`.

### `IF / ELSEIF / ELSE`

```sql
CALL sp_customer_income_band(
    '0610b486422d4921ae7d2bf64640c50b'
);
```

The procedure returns `high_income` for the sample customer's non-imputed
income of `$112,000`.

The smoke test calls four customers so that `unknown_income`, `low_income`,
`medium_income`, and `high_income` are all exercised.

## Choosing the right method

| Need | Preferred construct |
|---|---|
| Reuse one governed database operation | Stored procedure |
| Supply filtering choices | `IN` |
| Return a scalar to later SQL statements | `OUT` |
| Demonstrate one variable entering and leaving | `INOUT` |
| Check before the first repetition | `WHILE` |
| Run at least once before checking | `REPEAT` |
| Need explicit skip and exit behavior | `LOOP` with `ITERATE` and `LEAVE` |
| Choose among mutually exclusive outcomes | `IF / ELSEIF / ELSE` |

For set-based calculations, an ordinary `SELECT`, view, CTE, or window function
is generally preferable to a loop. The project uses loops here where they make
the course concepts visible, while the main analytical layer remains set-based
for performance and clarity.

## MySQL references

- [CREATE PROCEDURE and IN/OUT/INOUT parameters](https://dev.mysql.com/doc/refman/8.4/en/create-procedure.html)
- [WHILE syntax](https://dev.mysql.com/doc/refman/8.4/en/while.html)
- [REPEAT syntax](https://dev.mysql.com/doc/refman/8.4/en/repeat.html)
- [LOOP syntax](https://dev.mysql.com/doc/refman/8.4/en/loop.html)
- [LOAD DATA CSV handling](https://dev.mysql.com/doc/refman/8.4/en/load-data.html)

## Portfolio / mock-interview summary

> I built a governed SQL project around 323,544 Starbucks source records. The
> pipeline preserves the raw files, validates and normalizes nested fields,
> creates typed relational tables, logs every cleaning decision, and builds
> 76,277 sequence-aware offer exposures so repeated campaigns cannot produce
> impossible conversion rates. I then added a MySQL stored-program layer
> demonstrating IN, OUT, and INOUT parameters, all three MySQL loop types, and
> conditional logic through customer and offer use cases. The final checks
> reconcile all rows, find no foreign-key or hard validation errors, and verify
> that the source hashes are unchanged.
