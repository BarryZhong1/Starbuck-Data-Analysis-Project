-- Starbucks customer analytics with window functions.
--
-- These are analytical views only. They read from the clean and deduplicated
-- layers and never update the raw source tables.

-- ---------------------------------------------------------------------------
-- 1. ROW_NUMBER: put every customer's events in chronological order
-- ---------------------------------------------------------------------------

CREATE VIEW vw_customer_event_sequence AS
SELECT
    event_id,
    customer_id,
    event_type,
    event_label,
    offer_id,
    amount,
    reward,
    event_hour,
    event_day_number,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY event_hour, event_id
    ) AS customer_event_number
FROM vw_transcript_event_deduplicated;

-- ---------------------------------------------------------------------------
-- 2. DENSE_RANK: compare spending within each customer gender group
-- ---------------------------------------------------------------------------

CREATE VIEW vw_customer_spend_rank_by_gender AS
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.gender_label,
        COUNT(t.event_id) AS transaction_count,
        ROUND(COALESCE(SUM(t.amount), 0), 2) AS total_spend,
        ROUND(AVG(t.amount), 2) AS average_transaction_value
    FROM customer_profile AS c
    LEFT JOIN vw_transcript_event_deduplicated AS t
        ON t.customer_id = c.customer_id
       AND t.event_type = 'transaction'
    GROUP BY
        c.customer_id,
        c.gender_label
)
SELECT
    customer_id,
    gender_label,
    transaction_count,
    total_spend,
    average_transaction_value,
    DENSE_RANK() OVER (
        PARTITION BY gender_label
        ORDER BY total_spend DESC
    ) AS spending_rank_within_gender
FROM customer_spend;

-- ---------------------------------------------------------------------------
-- 3. SUM OVER: show how each customer's spending accumulates over time
-- ---------------------------------------------------------------------------

CREATE VIEW vw_customer_running_spend AS
SELECT
    event_id,
    customer_id,
    event_hour,
    event_day_number,
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
WHERE event_type = 'transaction';

-- ---------------------------------------------------------------------------
-- 4. COUNT OVER: calculate the count and percentage in every age band
-- ---------------------------------------------------------------------------

CREATE VIEW vw_customer_age_distribution AS
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
    age_band_order,
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
FROM age_bands;
