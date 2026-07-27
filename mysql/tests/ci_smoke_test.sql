USE starbucks_analytics;

CALL sp_get_all_events();
CALL sp_gender_percentage_by_age(30);
CALL sp_gender_age_percentage('F', 30);

CALL sp_event_count('offer completed', @event_count);
SELECT @event_count AS offer_completed_count;

SET @age_or_count = 30;
CALL sp_customer_count_at_or_above_age(@age_or_count);
SELECT @age_or_count AS customers_age_30_or_above;

CALL sp_age_band_summary_while(20, 59, 10);
CALL sp_offer_metrics_repeat();
CALL sp_even_numbers_loop(10);
CALL sp_customer_income_band('cccccccccccccccccccccccccccccccc');
