USE starbucks_analytics;

-- The generated clean CSVs are mounted read-only at /var/lib/mysql-files.
-- Empty CSV fields are converted to SQL NULL explicitly.

LOAD DATA INFILE '/var/lib/mysql-files/portfolio_clean.csv'
INTO TABLE portfolio
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    offer_id,
    offer_type,
    offer_type_label,
    reward,
    difficulty,
    duration_days,
    @channels_json,
    channel_web,
    channel_email,
    channel_mobile,
    channel_social,
    channel_count,
    source_row_id
)
SET channels_json = CAST(@channels_json AS JSON);

LOAD DATA INFILE '/var/lib/mysql-files/portfolio_channel.csv'
INTO TABLE portfolio_channel
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(offer_id, channel);

LOAD DATA INFILE '/var/lib/mysql-files/customer_profile_clean.csv'
INTO TABLE customer_profile
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    customer_id,
    @gender_code,
    gender_label,
    @age_clean,
    age_imputed,
    age_was_imputed,
    membership_date,
    membership_year,
    @income_clean,
    income_imputed,
    income_was_imputed,
    profile_status,
    source_row_id
)
SET
    gender_code = NULLIF(@gender_code, ''),
    age_clean = NULLIF(@age_clean, ''),
    income_clean = NULLIF(@income_clean, '');

LOAD DATA INFILE '/var/lib/mysql-files/transcript_event_clean.csv'
INTO TABLE transcript_event
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    event_id,
    customer_id,
    event_type,
    event_label,
    @value_json,
    @offer_id,
    @amount,
    @reward,
    event_hour,
    event_day_number,
    duplicate_rank,
    is_exact_duplicate,
    source_row_id
)
SET
    value_json = CAST(@value_json AS JSON),
    offer_id = NULLIF(@offer_id, ''),
    amount = NULLIF(@amount, ''),
    reward = NULLIF(@reward, '');

LOAD DATA INFILE '/var/lib/mysql-files/offer_exposure_clean.csv'
INTO TABLE offer_exposure
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    exposure_id,
    customer_id,
    offer_id,
    received_hour,
    expires_hour,
    @next_received_event_id,
    @next_received_hour,
    @viewed_event_id,
    @viewed_hour,
    @completed_event_id,
    @completed_hour,
    @qualified_completed_event_id,
    @qualified_completed_hour,
    was_viewed,
    was_completed_in_window,
    was_completed_after_view
)
SET
    next_received_event_id = NULLIF(@next_received_event_id, ''),
    next_received_hour = NULLIF(@next_received_hour, ''),
    viewed_event_id = NULLIF(@viewed_event_id, ''),
    viewed_hour = NULLIF(@viewed_hour, ''),
    completed_event_id = NULLIF(@completed_event_id, ''),
    completed_hour = NULLIF(@completed_hour, ''),
    qualified_completed_event_id = NULLIF(@qualified_completed_event_id, ''),
    qualified_completed_hour = NULLIF(@qualified_completed_hour, '');
