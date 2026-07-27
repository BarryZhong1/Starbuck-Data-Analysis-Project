-- Read-only checks to run after 01_transform.sql.

SELECT *
FROM data_quality_summary
ORDER BY
    CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
    metric_name;

SELECT
    severity,
    rule_code,
    source_table,
    COUNT(*) AS affected_rows
FROM etl_error_log
GROUP BY severity, rule_code, source_table
ORDER BY
    CASE severity WHEN 'ERROR' THEN 1 ELSE 2 END,
    affected_rows DESC;

SELECT
    'portfolio' AS table_name,
    COUNT(*) AS row_count
FROM portfolio
UNION ALL
SELECT 'portfolio_channel', COUNT(*) FROM portfolio_channel
UNION ALL
SELECT 'customer_profile', COUNT(*) FROM customer_profile
UNION ALL
SELECT 'transcript_event', COUNT(*) FROM transcript_event
UNION ALL
SELECT 'offer_exposure', COUNT(*) FROM offer_exposure
UNION ALL
SELECT 'vw_transcript_event_deduplicated', COUNT(*) FROM vw_transcript_event_deduplicated;

SELECT *
FROM pragma_foreign_key_check;

SELECT
    offer_type,
    COUNT(*) AS offer_count,
    ROUND(AVG(difficulty), 2) AS avg_difficulty,
    ROUND(AVG(duration_days), 2) AS avg_duration_days,
    ROUND(AVG(reward), 2) AS avg_reward
FROM portfolio
GROUP BY offer_type
ORDER BY offer_type;

SELECT *
FROM vw_offer_performance
ORDER BY view_rate DESC, qualified_completion_rate_from_received DESC;
