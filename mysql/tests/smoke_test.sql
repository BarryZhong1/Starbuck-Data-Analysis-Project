USE starbucks_analytics;

-- Confirm that every presentation-aligned stored procedure was installed.
SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = DATABASE()
  AND routine_name IN (
      'sp_get_all_events',
      'sp_gender_percentage_by_age',
      'sp_gender_age_percentage',
      'sp_event_count',
      'sp_customer_count_at_or_above_age',
      'sp_age_band_summary_while',
      'sp_offer_metrics_repeat',
      'sp_even_numbers_loop',
      'sp_customer_income_band'
  )
ORDER BY routine_name;

-- One IN parameter. Expected total for age 60+: 5,875.
CALL sp_gender_percentage_by_age(60);

-- Multiple IN parameters. Expected F count for age 30+: 5,691.
CALL sp_gender_age_percentage('F', 30);

-- OUT parameter. Expected deduplicated offer_completed count: 33,182.
CALL sp_event_count('offer completed', @event_count);
SELECT @event_count AS offer_completed_count;

-- INOUT parameter. Input age 30 becomes expected count 13,251.
SET @age_or_count = 30;
CALL sp_customer_count_at_or_above_age(@age_or_count);
SELECT @age_or_count AS customers_age_30_or_above;

-- WHILE, REPEAT, and LOOP.
CALL sp_age_band_summary_while(20, 89, 10);
CALL sp_offer_metrics_repeat();
CALL sp_even_numbers_loop(10);

-- IF / ELSEIF / ELSE. Exercise every branch.
CALL sp_customer_income_band('68be06ca386d4c31939f3a4f0e3dd783');
CALL sp_customer_income_band('389bc3fa690240e798340f5a15918d5c');
CALL sp_customer_income_band('78afa995795e4d85b5d9ceeca43f5fef');
CALL sp_customer_income_band('0610b486422d4921ae7d2bf64640c50b');

-- The no-parameter procedure returns all deduplicated events and is omitted
-- here to keep smoke-test output compact. Run it explicitly when needed:
-- CALL sp_get_all_events();
