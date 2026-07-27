# Starbucks Customer Data — Window Function Homework

## How window functions help

Window functions calculate a value across related rows while keeping each
original row visible. This is useful for Starbucks customer data because an
analyst can preserve every customer event or transaction while also:

- ordering each customer's actions through time;
- comparing a customer with others in the same demographic segment; and
- measuring how a customer's spending accumulates after each transaction.

Unlike `GROUP BY`, a window function does not collapse a customer's many rows
into one summary row.

The project uses the cleaned tables and the deduplicated event view. None of
these queries changes the raw data.

## 1. Sequence customer events with `ROW_NUMBER()`

**Business question:** In what order did each customer receive, view, and
complete offers or make transactions?

```sql
SELECT
    customer_id,
    event_type,
    event_hour,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY event_hour, event_id
    ) AS customer_event_number
FROM vw_transcript_event_deduplicated
ORDER BY customer_id, customer_event_number;
```

- `PARTITION BY customer_id` restarts numbering for each customer.
- `ORDER BY event_hour, event_id` produces a deterministic chronological order.
- This can reveal whether an offer was viewed before it was completed.

Reusable project view: `vw_customer_event_sequence`.

## 2. Rank customer spending within gender with `DENSE_RANK()`

**Business question:** Who are the highest-spending customers within each gender
group?

```sql
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.gender_label,
        COUNT(t.event_id) AS transaction_count,
        ROUND(COALESCE(SUM(t.amount), 0), 2) AS total_spend
    FROM customer_profile AS c
    LEFT JOIN vw_transcript_event_deduplicated AS t
        ON t.customer_id = c.customer_id
       AND t.event_type = 'transaction'
    GROUP BY c.customer_id, c.gender_label
)
SELECT
    customer_id,
    gender_label,
    transaction_count,
    total_spend,
    DENSE_RANK() OVER (
        PARTITION BY gender_label
        ORDER BY total_spend DESC
    ) AS spending_rank_within_gender
FROM customer_spend
ORDER BY gender_label, spending_rank_within_gender;
```

- The grouped CTE first calculates one spending total per customer.
- `PARTITION BY gender_label` creates a separate leaderboard for each group.
- `DENSE_RANK()` gives tied spending totals the same rank without skipping the
  next rank.

Reusable project view: `vw_customer_spend_rank_by_gender`.

## 3. Calculate cumulative spending with `SUM() OVER`

**Business question:** How did each customer's total spending grow after every
transaction?

```sql
SELECT
    customer_id,
    event_hour,
    amount,
    ROUND(
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY event_hour, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_spend
FROM vw_transcript_event_deduplicated
WHERE event_type = 'transaction'
ORDER BY customer_id, event_hour, event_id;
```

- The window restarts for each customer.
- Rows are accumulated in chronological order.
- The explicit `ROWS` frame means the current result includes every transaction
  from that customer's first transaction through the current row.

Reusable project view: `vw_customer_running_spend`.

## Why these three criteria matter

| Window function | Customer-analysis use | Rows preserved? |
|---|---|:---:|
| `ROW_NUMBER()` | Customer event sequence | Yes |
| `DENSE_RANK()` | Segment-level spending comparison | Yes |
| `SUM() OVER` | Running customer lifetime spend | Yes |

Together, the queries support behavioral analysis, customer segmentation, and
customer-value tracking without modifying the raw source files.

## Additional exercise: age-distribution percentage with `COUNT() OVER`

The class example is also included. The query keeps one row per customer while
showing both the total number of customers with a known age and the number in
that customer's age group.

```sql
WITH age_bands AS (
    SELECT
        customer_id,
        age_clean,
        CASE
            WHEN age_clean < 30 THEN 1
            WHEN age_clean < 40 THEN 2
            WHEN age_clean < 50 THEN 3
            WHEN age_clean < 60 THEN 4
            WHEN age_clean < 70 THEN 5
            WHEN age_clean < 80 THEN 6
            ELSE 7
        END AS age_band_order,
        CASE
            WHEN age_clean < 30 THEN 'Under 30'
            WHEN age_clean < 40 THEN '30-39'
            WHEN age_clean < 50 THEN '40-49'
            WHEN age_clean < 60 THEN '50-59'
            WHEN age_clean < 70 THEN '60-69'
            WHEN age_clean < 80 THEN '70-79'
            ELSE '80+'
        END AS age_group
    FROM customer_profile
    WHERE age_clean IS NOT NULL
)
SELECT
    customer_id,
    age_clean,
    age_group,
    COUNT(*) OVER () AS total_customers_with_known_age,
    COUNT(*) OVER (
        PARTITION BY age_group
    ) AS age_group_count,
    ROUND(
        100.0 * COUNT(*) OVER (PARTITION BY age_group) /
        COUNT(*) OVER (),
        2
    ) AS age_group_percentage
FROM age_bands
ORDER BY age_band_order, customer_id;
```

This version corrects two problems visible in the screenshot:

- it includes both `40-49` and separate `70-79`/`80+` groups; and
- it uses `age_clean` and excludes unknown ages, instead of counting the raw
  age `118` missing-value marker as a real customer age.

Reusable project view: `vw_customer_age_distribution`. The compact result is
exported as `output/age_distribution.csv`.

### Age-distribution result

| Age group | Customers | Percentage |
|---|---:|---:|
| Under 30 | 1,574 | 10.62% |
| 30-39 | 1,526 | 10.29% |
| 40-49 | 2,309 | 15.58% |
| 50-59 | 3,541 | 23.89% |
| 60-69 | 2,991 | 20.18% |
| 70-79 | 1,782 | 12.02% |
| 80+ | 1,102 | 7.43% |
| **Total with known age** | **14,825** | **100% before rounding** |

There are 2,175 additional profiles with unknown age. They are excluded from
this distribution instead of being assigned to the median-age group. The seven
displayed percentages total 100.01% because each group is independently rounded
to two decimal places.
