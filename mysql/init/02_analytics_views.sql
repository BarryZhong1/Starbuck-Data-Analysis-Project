USE starbucks_analytics;

CREATE OR REPLACE VIEW vw_transcript_event_deduplicated AS
SELECT *
FROM transcript_event
WHERE is_exact_duplicate = 0;

CREATE OR REPLACE VIEW vw_customer_event_sequence AS
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

CREATE OR REPLACE VIEW vw_customer_spend_rank_by_gender AS
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
    GROUP BY c.customer_id, c.gender_label
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

CREATE OR REPLACE VIEW vw_customer_running_spend AS
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

CREATE OR REPLACE VIEW vw_customer_age_distribution AS
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
    COUNT(*) OVER (PARTITION BY age_group) AS age_group_count,
    ROUND(
        100.0 * COUNT(*) OVER (PARTITION BY age_group)
        / COUNT(*) OVER (),
        2
    ) AS age_group_percentage
FROM age_bands;

CREATE OR REPLACE VIEW vw_customer_offer_funnel AS
SELECT
    customer_id,
    offer_id,
    COUNT(*) AS received_count,
    SUM(was_viewed) AS viewed_count,
    SUM(was_completed_in_window) AS completed_in_window_count,
    SUM(was_completed_after_view) AS completed_after_view_count,
    SUM(
        CASE
            WHEN was_completed_in_window = 1 AND was_completed_after_view = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_prior_view_count,
    MIN(received_hour) AS first_received_hour,
    MIN(viewed_hour) AS first_viewed_hour,
    MIN(qualified_completed_hour) AS first_qualified_completed_hour
FROM offer_exposure
GROUP BY customer_id, offer_id;

CREATE OR REPLACE VIEW vw_offer_performance AS
SELECT
    p.offer_id,
    p.offer_type,
    p.offer_type_label,
    p.difficulty,
    p.reward,
    p.duration_days,
    p.channel_web,
    p.channel_email,
    p.channel_mobile,
    p.channel_social,
    COALESCE(SUM(f.received_count), 0) AS received_count,
    COALESCE(SUM(f.viewed_count), 0) AS viewed_count,
    COALESCE(SUM(f.completed_in_window_count), 0) AS completed_in_window_count,
    COALESCE(SUM(f.completed_after_view_count), 0) AS completed_after_view_count,
    COALESCE(SUM(f.completed_without_prior_view_count), 0)
        AS completed_without_prior_view_count,
    ROUND(
        1.0 * COALESCE(SUM(f.viewed_count), 0)
        / NULLIF(COALESCE(SUM(f.received_count), 0), 0),
        4
    ) AS view_rate,
    ROUND(
        1.0 * COALESCE(SUM(f.completed_after_view_count), 0)
        / NULLIF(COALESCE(SUM(f.received_count), 0), 0),
        4
    ) AS qualified_completion_rate_from_received,
    ROUND(
        1.0 * COALESCE(SUM(f.completed_after_view_count), 0)
        / NULLIF(COALESCE(SUM(f.viewed_count), 0), 0),
        4
    ) AS qualified_completion_rate_from_viewed
FROM portfolio AS p
LEFT JOIN vw_customer_offer_funnel AS f
    ON f.offer_id = p.offer_id
GROUP BY
    p.offer_id,
    p.offer_type,
    p.offer_type_label,
    p.difficulty,
    p.reward,
    p.duration_days,
    p.channel_web,
    p.channel_email,
    p.channel_mobile,
    p.channel_social;
