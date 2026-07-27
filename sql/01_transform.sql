BEGIN IMMEDIATE;

-- ---------------------------------------------------------------------------
-- 1. Validation and error logging
-- REGEXP is supplied by src/run_pipeline.py.
-- ---------------------------------------------------------------------------

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_portfolio',
    source_row_id,
    'id',
    id,
    'INVALID_OFFER_ID',
    'Offer ID must contain exactly 32 lowercase hexadecimal characters.'
FROM raw_portfolio
WHERE TRIM(COALESCE(id, '')) NOT REGEXP '^[0-9a-f]{32}$';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_portfolio',
    source_row_id,
    'channels',
    channels,
    'INVALID_CHANNEL_JSON',
    'Channel list could not be normalized to valid JSON.'
FROM raw_portfolio
WHERE channels IS NULL
   OR json_valid(REPLACE(TRIM(channels), '''', '"')) = 0;

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_portfolio',
    source_row_id,
    column_name,
    raw_value,
    'INVALID_INTEGER',
    'Expected a nonnegative integer.'
FROM (
    SELECT source_row_id, 'reward' AS column_name, reward AS raw_value FROM raw_portfolio
    UNION ALL
    SELECT source_row_id, 'difficulty', difficulty FROM raw_portfolio
    UNION ALL
    SELECT source_row_id, 'duration', duration FROM raw_portfolio
)
WHERE TRIM(COALESCE(raw_value, '')) NOT REGEXP '^[0-9]+$';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_portfolio',
    source_row_id,
    'offer_type',
    offer_type,
    'INVALID_OFFER_TYPE',
    'Offer type must be bogo, discount, or informational.'
FROM raw_portfolio
WHERE LOWER(TRIM(COALESCE(offer_type, ''))) NOT IN ('bogo', 'discount', 'informational');

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_profile',
    source_row_id,
    'id',
    id,
    'INVALID_CUSTOMER_ID',
    'Customer ID must contain exactly 32 lowercase hexadecimal characters.'
FROM raw_profile
WHERE TRIM(COALESCE(id, '')) NOT REGEXP '^[0-9a-f]{32}$';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_profile',
    source_row_id,
    'age',
    age,
    'INVALID_AGE',
    'Age must be an integer from 18 through 118.'
FROM raw_profile
WHERE TRIM(COALESCE(age, '')) NOT REGEXP '^[0-9]+$'
   OR CAST(TRIM(age) AS INTEGER) NOT BETWEEN 18 AND 118;

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_profile',
    source_row_id,
    'became_member_on',
    became_member_on,
    'INVALID_MEMBERSHIP_DATE',
    'Membership date must use a valid YYYYMMDD representation.'
FROM raw_profile
WHERE TRIM(COALESCE(became_member_on, '')) NOT REGEXP '^[0-9]{8}$'
   OR date(
        SUBSTR(TRIM(became_member_on), 1, 4) || '-' ||
        SUBSTR(TRIM(became_member_on), 5, 2) || '-' ||
        SUBSTR(TRIM(became_member_on), 7, 2)
      ) IS NULL;

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_profile',
    source_row_id,
    'income',
    income,
    'INVALID_INCOME',
    'Income must be blank or a nonnegative number.'
FROM raw_profile
WHERE income IS NOT NULL
  AND TRIM(income) NOT REGEXP '^[0-9]+([.][0-9]+)?$';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'WARNING',
    'raw_profile',
    source_row_id,
    'gender',
    gender,
    'MISSING_GENDER',
    'Blank gender was standardized to the Unknown category.'
FROM raw_profile
WHERE gender IS NULL OR TRIM(gender) = '';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'WARNING',
    'raw_profile',
    source_row_id,
    'age',
    age,
    'AGE_SENTINEL_118',
    'Age 118 was treated as an undocumented missing-value sentinel and imputed separately.'
FROM raw_profile
WHERE TRIM(age) = '118';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'WARNING',
    'raw_profile',
    source_row_id,
    'income',
    income,
    'MISSING_INCOME',
    'Blank income was retained as NULL and imputed separately.'
FROM raw_profile
WHERE income IS NULL OR TRIM(income) = '';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_transcript',
    source_row_id,
    'person',
    person,
    'INVALID_EVENT_CUSTOMER_ID',
    'Event customer ID must contain exactly 32 lowercase hexadecimal characters.'
FROM raw_transcript
WHERE TRIM(COALESCE(person, '')) NOT REGEXP '^[0-9a-f]{32}$';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_transcript',
    source_row_id,
    'event',
    event,
    'INVALID_EVENT_TYPE',
    'Event must be transaction, offer received, offer viewed, or offer completed.'
FROM raw_transcript
WHERE LOWER(TRIM(COALESCE(event, ''))) NOT IN
      ('transaction', 'offer received', 'offer viewed', 'offer completed');

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_transcript',
    source_row_id,
    'value',
    value,
    'INVALID_VALUE_JSON',
    'Event value dictionary could not be normalized to valid JSON.'
FROM raw_transcript
WHERE value IS NULL
   OR json_valid(REPLACE(TRIM(value), '''', '"')) = 0;

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_transcript',
    source_row_id,
    'time',
    time,
    'INVALID_EVENT_TIME',
    'Event time must be a nonnegative integer number of hours.'
FROM raw_transcript
WHERE TRIM(COALESCE(time, '')) NOT REGEXP '^[0-9]+$';

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'ERROR',
    'raw_transcript',
    source_row_id,
    'person',
    person,
    'ORPHAN_EVENT_CUSTOMER',
    'Event refers to a customer not present in the profile file.'
FROM raw_transcript AS t
WHERE NOT EXISTS (
    SELECT 1
    FROM raw_profile AS p
    WHERE TRIM(p.id) = TRIM(t.person)
);

-- ---------------------------------------------------------------------------
-- 2. Clean portfolio and expand the channels JSON list
-- ---------------------------------------------------------------------------

CREATE TABLE portfolio (
    offer_id            TEXT PRIMARY KEY
                        CHECK (
                            LENGTH(offer_id) = 32
                            AND offer_id NOT GLOB '*[^0-9a-f]*'
                        ),
    offer_type          TEXT NOT NULL
                        CHECK (offer_type IN ('bogo', 'discount', 'informational')),
    offer_type_label    TEXT NOT NULL,
    reward              INTEGER NOT NULL CHECK (reward >= 0),
    difficulty          INTEGER NOT NULL CHECK (difficulty >= 0),
    duration_days       INTEGER NOT NULL CHECK (duration_days > 0),
    channels_json       TEXT NOT NULL CHECK (json_valid(channels_json)),
    channel_web         INTEGER NOT NULL CHECK (channel_web IN (0, 1)),
    channel_email       INTEGER NOT NULL CHECK (channel_email IN (0, 1)),
    channel_mobile      INTEGER NOT NULL CHECK (channel_mobile IN (0, 1)),
    channel_social      INTEGER NOT NULL CHECK (channel_social IN (0, 1)),
    channel_count       INTEGER NOT NULL CHECK (channel_count >= 0),
    source_row_id       INTEGER NOT NULL UNIQUE
);

WITH normalized AS (
    SELECT
        source_row_id,
        TRIM(id) AS offer_id,
        LOWER(TRIM(offer_type)) AS offer_type,
        CAST(TRIM(reward) AS INTEGER) AS reward,
        CAST(TRIM(difficulty) AS INTEGER) AS difficulty,
        CAST(TRIM(duration) AS INTEGER) AS duration_days,
        REPLACE(TRIM(channels), '''', '"') AS channels_json
    FROM raw_portfolio
    WHERE TRIM(COALESCE(id, '')) REGEXP '^[0-9a-f]{32}$'
      AND TRIM(COALESCE(reward, '')) REGEXP '^[0-9]+$'
      AND TRIM(COALESCE(difficulty, '')) REGEXP '^[0-9]+$'
      AND TRIM(COALESCE(duration, '')) REGEXP '^[0-9]+$'
      AND LOWER(TRIM(COALESCE(offer_type, ''))) IN ('bogo', 'discount', 'informational')
      AND json_valid(REPLACE(TRIM(channels), '''', '"')) = 1
)
INSERT INTO portfolio (
    offer_id,
    offer_type,
    offer_type_label,
    reward,
    difficulty,
    duration_days,
    channels_json,
    channel_web,
    channel_email,
    channel_mobile,
    channel_social,
    channel_count,
    source_row_id
)
SELECT
    offer_id,
    offer_type,
    CASE offer_type
        WHEN 'bogo' THEN 'BOGO'
        WHEN 'discount' THEN 'Discount'
        WHEN 'informational' THEN 'Informational'
    END,
    reward,
    difficulty,
    duration_days,
    channels_json,
    CASE WHEN EXISTS (
        SELECT 1 FROM json_each(channels_json) WHERE LOWER(TRIM(value)) = 'web'
    ) THEN 1 ELSE 0 END,
    CASE WHEN EXISTS (
        SELECT 1 FROM json_each(channels_json) WHERE LOWER(TRIM(value)) = 'email'
    ) THEN 1 ELSE 0 END,
    CASE WHEN EXISTS (
        SELECT 1 FROM json_each(channels_json) WHERE LOWER(TRIM(value)) = 'mobile'
    ) THEN 1 ELSE 0 END,
    CASE WHEN EXISTS (
        SELECT 1 FROM json_each(channels_json) WHERE LOWER(TRIM(value)) = 'social'
    ) THEN 1 ELSE 0 END,
    (SELECT COUNT(*) FROM json_each(channels_json)),
    source_row_id
FROM normalized;

CREATE TABLE portfolio_channel (
    offer_id            TEXT NOT NULL REFERENCES portfolio(offer_id),
    channel             TEXT NOT NULL
                        CHECK (channel IN ('web', 'email', 'mobile', 'social')),
    PRIMARY KEY (offer_id, channel)
);

INSERT INTO portfolio_channel (offer_id, channel)
SELECT
    p.offer_id,
    LOWER(TRIM(j.value)) AS channel
FROM portfolio AS p
CROSS JOIN json_each(p.channels_json) AS j
WHERE LOWER(TRIM(j.value)) IN ('web', 'email', 'mobile', 'social');

-- ---------------------------------------------------------------------------
-- 3. Clean customer profile, convert types, and expose imputation explicitly
-- ---------------------------------------------------------------------------

CREATE TABLE customer_profile (
    customer_id         TEXT PRIMARY KEY
                        CHECK (
                            LENGTH(customer_id) = 32
                            AND customer_id NOT GLOB '*[^0-9a-f]*'
                        ),
    gender_code         TEXT CHECK (gender_code IN ('F', 'M', 'O') OR gender_code IS NULL),
    gender_label        TEXT NOT NULL
                        CHECK (gender_label IN ('Female', 'Male', 'Other', 'Unknown')),
    age_clean           INTEGER CHECK (age_clean BETWEEN 18 AND 117 OR age_clean IS NULL),
    age_imputed         INTEGER NOT NULL CHECK (age_imputed BETWEEN 18 AND 117),
    age_was_imputed     INTEGER NOT NULL CHECK (age_was_imputed IN (0, 1)),
    membership_date     TEXT NOT NULL,
    membership_year     INTEGER NOT NULL,
    income_clean        REAL CHECK (income_clean >= 0 OR income_clean IS NULL),
    income_imputed      REAL NOT NULL CHECK (income_imputed >= 0),
    income_was_imputed  INTEGER NOT NULL CHECK (income_was_imputed IN (0, 1)),
    profile_status      TEXT NOT NULL CHECK (profile_status IN ('Complete', 'Imputed')),
    source_row_id       INTEGER NOT NULL UNIQUE
);

WITH typed AS (
    SELECT
        source_row_id,
        TRIM(id) AS customer_id,
        CASE
            WHEN UPPER(TRIM(COALESCE(gender, ''))) IN ('F', 'M', 'O')
            THEN UPPER(TRIM(gender))
            ELSE NULL
        END AS gender_code,
        CASE
            WHEN TRIM(age) REGEXP '^[0-9]+$'
             AND CAST(TRIM(age) AS INTEGER) BETWEEN 18 AND 117
            THEN CAST(TRIM(age) AS INTEGER)
            ELSE NULL
        END AS age_clean,
        SUBSTR(TRIM(became_member_on), 1, 4) || '-' ||
        SUBSTR(TRIM(became_member_on), 5, 2) || '-' ||
        SUBSTR(TRIM(became_member_on), 7, 2) AS membership_date,
        CASE
            WHEN income IS NOT NULL
             AND TRIM(income) REGEXP '^[0-9]+([.][0-9]+)?$'
            THEN CAST(TRIM(income) AS REAL)
            ELSE NULL
        END AS income_clean
    FROM raw_profile
    WHERE TRIM(COALESCE(id, '')) REGEXP '^[0-9a-f]{32}$'
      AND TRIM(COALESCE(became_member_on, '')) REGEXP '^[0-9]{8}$'
),
age_ranked AS (
    SELECT
        age_clean,
        ROW_NUMBER() OVER (ORDER BY age_clean) AS rn,
        COUNT(*) OVER () AS n
    FROM typed
    WHERE age_clean IS NOT NULL
),
income_ranked AS (
    SELECT
        income_clean,
        ROW_NUMBER() OVER (ORDER BY income_clean) AS rn,
        COUNT(*) OVER () AS n
    FROM typed
    WHERE income_clean IS NOT NULL
),
medians AS (
    SELECT
        CAST((
            SELECT AVG(age_clean)
            FROM age_ranked
            WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
        ) AS INTEGER) AS median_age,
        (
            SELECT AVG(income_clean)
            FROM income_ranked
            WHERE rn IN ((n + 1) / 2, (n + 2) / 2)
        ) AS median_income
)
INSERT INTO customer_profile (
    customer_id,
    gender_code,
    gender_label,
    age_clean,
    age_imputed,
    age_was_imputed,
    membership_date,
    membership_year,
    income_clean,
    income_imputed,
    income_was_imputed,
    profile_status,
    source_row_id
)
SELECT
    t.customer_id,
    t.gender_code,
    CASE t.gender_code
        WHEN 'F' THEN 'Female'
        WHEN 'M' THEN 'Male'
        WHEN 'O' THEN 'Other'
        ELSE 'Unknown'
    END,
    t.age_clean,
    COALESCE(t.age_clean, m.median_age),
    CASE WHEN t.age_clean IS NULL THEN 1 ELSE 0 END,
    t.membership_date,
    CAST(SUBSTR(t.membership_date, 1, 4) AS INTEGER),
    t.income_clean,
    COALESCE(t.income_clean, m.median_income),
    CASE WHEN t.income_clean IS NULL THEN 1 ELSE 0 END,
    CASE
        WHEN t.gender_code IS NULL OR t.age_clean IS NULL OR t.income_clean IS NULL
        THEN 'Imputed'
        ELSE 'Complete'
    END,
    t.source_row_id
FROM typed AS t
CROSS JOIN medians AS m;

-- ---------------------------------------------------------------------------
-- 4. Normalize transcript JSON and expand event-specific values
-- ---------------------------------------------------------------------------

CREATE TABLE transcript_event (
    event_id                INTEGER PRIMARY KEY,
    customer_id             TEXT NOT NULL REFERENCES customer_profile(customer_id),
    event_type              TEXT NOT NULL
                            CHECK (event_type IN (
                                'transaction',
                                'offer_received',
                                'offer_viewed',
                                'offer_completed'
                            )),
    event_label             TEXT NOT NULL,
    value_json              TEXT NOT NULL CHECK (json_valid(value_json)),
    offer_id                TEXT REFERENCES portfolio(offer_id),
    amount                  REAL CHECK (amount >= 0 OR amount IS NULL),
    reward                  INTEGER CHECK (reward >= 0 OR reward IS NULL),
    event_hour              INTEGER NOT NULL CHECK (event_hour >= 0),
    event_day_number        INTEGER NOT NULL CHECK (event_day_number >= 0),
    duplicate_rank          INTEGER NOT NULL CHECK (duplicate_rank >= 1),
    is_exact_duplicate      INTEGER NOT NULL CHECK (is_exact_duplicate IN (0, 1)),
    source_row_id           INTEGER NOT NULL UNIQUE
);

WITH normalized AS (
    SELECT
        source_row_id,
        TRIM(person) AS customer_id,
        REPLACE(LOWER(TRIM(event)), ' ', '_') AS event_type,
        REPLACE(TRIM(value), '''', '"') AS value_json,
        CAST(TRIM(time) AS INTEGER) AS event_hour
    FROM raw_transcript
    WHERE TRIM(COALESCE(person, '')) REGEXP '^[0-9a-f]{32}$'
      AND LOWER(TRIM(COALESCE(event, ''))) IN
          ('transaction', 'offer received', 'offer viewed', 'offer completed')
      AND json_valid(REPLACE(TRIM(value), '''', '"')) = 1
      AND TRIM(COALESCE(time, '')) REGEXP '^[0-9]+$'
),
expanded AS (
    SELECT
        source_row_id,
        customer_id,
        event_type,
        value_json,
        COALESCE(
            json_extract(value_json, '$."offer id"'),
            json_extract(value_json, '$.offer_id')
        ) AS offer_id,
        CASE
            WHEN json_type(value_json, '$.amount') IN ('integer', 'real')
            THEN CAST(json_extract(value_json, '$.amount') AS REAL)
            ELSE NULL
        END AS amount,
        CASE
            WHEN json_type(value_json, '$.reward') = 'integer'
            THEN CAST(json_extract(value_json, '$.reward') AS INTEGER)
            ELSE NULL
        END AS reward,
        event_hour
    FROM normalized
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, event_type, value_json, event_hour
            ORDER BY source_row_id
        ) AS duplicate_rank
    FROM expanded
)
INSERT INTO transcript_event (
    event_id,
    customer_id,
    event_type,
    event_label,
    value_json,
    offer_id,
    amount,
    reward,
    event_hour,
    event_day_number,
    duplicate_rank,
    is_exact_duplicate,
    source_row_id
)
SELECT
    source_row_id + 1 AS event_id,
    customer_id,
    event_type,
    CASE event_type
        WHEN 'transaction' THEN 'Transaction'
        WHEN 'offer_received' THEN 'Offer Received'
        WHEN 'offer_viewed' THEN 'Offer Viewed'
        WHEN 'offer_completed' THEN 'Offer Completed'
    END,
    value_json,
    offer_id,
    amount,
    reward,
    event_hour,
    CAST(event_hour / 24 AS INTEGER),
    duplicate_rank,
    CASE WHEN duplicate_rank > 1 THEN 1 ELSE 0 END,
    source_row_id
FROM ranked
WHERE EXISTS (
    SELECT 1
    FROM customer_profile AS c
    WHERE c.customer_id = ranked.customer_id
)
AND (
    ranked.offer_id IS NULL
    OR EXISTS (
        SELECT 1
        FROM portfolio AS p
        WHERE p.offer_id = ranked.offer_id
    )
);

INSERT INTO etl_error_log
    (run_id, severity, source_table, source_row_id, column_name, raw_value, rule_code, message)
SELECT
    (SELECT MAX(run_id) FROM etl_run),
    'WARNING',
    'raw_transcript',
    source_row_id,
    NULL,
    NULL,
    'EXACT_DUPLICATE_EVENT',
    'Exact repeated event was retained and flagged; use the deduplicated view for conservative analysis.'
FROM transcript_event
WHERE is_exact_duplicate = 1;

CREATE INDEX idx_transcript_customer_time
    ON transcript_event(customer_id, event_hour);

CREATE INDEX idx_transcript_offer_event
    ON transcript_event(offer_id, event_type);

CREATE INDEX idx_transcript_event_type
    ON transcript_event(event_type);

CREATE INDEX idx_transcript_customer_event_duplicate
    ON transcript_event(customer_id, event_type, is_exact_duplicate);

CREATE INDEX idx_transcript_exposure_lookup
    ON transcript_event(
        customer_id,
        offer_id,
        event_type,
        is_exact_duplicate,
        event_hour,
        event_id
    );

-- ---------------------------------------------------------------------------
-- 5. Sequence-aware offer exposures and analytics views
-- ---------------------------------------------------------------------------

CREATE VIEW vw_transcript_event_deduplicated AS
SELECT *
FROM transcript_event
WHERE is_exact_duplicate = 0;

-- One row per offer-received event. A view or completion is matched only when
-- it occurs after receipt, before expiration, and before the next receipt of
-- the same offer. This prevents one downstream event from being counted
-- against overlapping/repeated exposures.
CREATE TABLE offer_exposure (
    exposure_id                    INTEGER PRIMARY KEY,
    customer_id                    TEXT NOT NULL REFERENCES customer_profile(customer_id),
    offer_id                       TEXT NOT NULL REFERENCES portfolio(offer_id),
    received_hour                  INTEGER NOT NULL CHECK (received_hour >= 0),
    expires_hour                   INTEGER NOT NULL CHECK (expires_hour >= received_hour),
    next_received_event_id         INTEGER,
    next_received_hour             INTEGER,
    viewed_event_id                INTEGER REFERENCES transcript_event(event_id),
    viewed_hour                    INTEGER,
    completed_event_id             INTEGER REFERENCES transcript_event(event_id),
    completed_hour                 INTEGER,
    qualified_completed_event_id   INTEGER REFERENCES transcript_event(event_id),
    qualified_completed_hour       INTEGER,
    was_viewed                     INTEGER NOT NULL CHECK (was_viewed IN (0, 1)),
    was_completed_in_window        INTEGER NOT NULL
                                   CHECK (was_completed_in_window IN (0, 1)),
    was_completed_after_view       INTEGER NOT NULL
                                   CHECK (was_completed_after_view IN (0, 1)),
    CHECK (
        (viewed_event_id IS NULL AND viewed_hour IS NULL AND was_viewed = 0)
        OR
        (viewed_event_id IS NOT NULL AND viewed_hour IS NOT NULL AND was_viewed = 1)
    ),
    CHECK (
        (completed_event_id IS NULL AND completed_hour IS NULL
         AND was_completed_in_window = 0)
        OR
        (completed_event_id IS NOT NULL AND completed_hour IS NOT NULL
         AND was_completed_in_window = 1)
    ),
    CHECK (
        (qualified_completed_event_id IS NULL
         AND qualified_completed_hour IS NULL
         AND was_completed_after_view = 0)
        OR
        (qualified_completed_event_id IS NOT NULL
         AND qualified_completed_hour IS NOT NULL
         AND was_completed_after_view = 1)
    )
);

WITH received AS (
    SELECT
        e.event_id AS exposure_id,
        e.customer_id,
        e.offer_id,
        e.event_hour AS received_hour,
        e.event_hour + (24 * p.duration_days) AS expires_hour,
        LEAD(e.event_id) OVER (
            PARTITION BY e.customer_id, e.offer_id
            ORDER BY e.event_hour, e.event_id
        ) AS next_received_event_id,
        LEAD(e.event_hour) OVER (
            PARTITION BY e.customer_id, e.offer_id
            ORDER BY e.event_hour, e.event_id
        ) AS next_received_hour
    FROM vw_transcript_event_deduplicated AS e
    JOIN portfolio AS p
        ON p.offer_id = e.offer_id
    WHERE e.event_type = 'offer_received'
),
matched_views AS (
    SELECT
        r.*,
        (
            SELECT e.event_id
            FROM vw_transcript_event_deduplicated AS e
            WHERE e.customer_id = r.customer_id
              AND e.offer_id = r.offer_id
              AND e.event_type = 'offer_viewed'
              AND (
                    e.event_hour > r.received_hour
                    OR (
                        e.event_hour = r.received_hour
                        AND e.event_id > r.exposure_id
                    )
                  )
              AND e.event_hour <= r.expires_hour
              AND (
                    r.next_received_event_id IS NULL
                    OR e.event_hour < r.next_received_hour
                    OR (
                        e.event_hour = r.next_received_hour
                        AND e.event_id < r.next_received_event_id
                    )
                  )
            ORDER BY e.event_hour, e.event_id
            LIMIT 1
        ) AS viewed_event_id
    FROM received AS r
),
view_details AS (
    SELECT
        v.*,
        viewed.event_hour AS viewed_hour
    FROM matched_views AS v
    LEFT JOIN transcript_event AS viewed
        ON viewed.event_id = v.viewed_event_id
),
matched_completions AS (
    SELECT
        v.*,
        (
            SELECT e.event_id
            FROM vw_transcript_event_deduplicated AS e
            WHERE e.customer_id = v.customer_id
              AND e.offer_id = v.offer_id
              AND e.event_type = 'offer_completed'
              AND (
                    e.event_hour > v.received_hour
                    OR (
                        e.event_hour = v.received_hour
                        AND e.event_id > v.exposure_id
                    )
                  )
              AND e.event_hour <= v.expires_hour
              AND (
                    v.next_received_event_id IS NULL
                    OR e.event_hour < v.next_received_hour
                    OR (
                        e.event_hour = v.next_received_hour
                        AND e.event_id < v.next_received_event_id
                    )
                  )
            ORDER BY e.event_hour, e.event_id
            LIMIT 1
        ) AS completed_event_id,
        (
            SELECT e.event_id
            FROM vw_transcript_event_deduplicated AS e
            WHERE v.viewed_event_id IS NOT NULL
              AND e.customer_id = v.customer_id
              AND e.offer_id = v.offer_id
              AND e.event_type = 'offer_completed'
              AND (
                    e.event_hour > v.viewed_hour
                    OR (
                        e.event_hour = v.viewed_hour
                        AND e.event_id > v.viewed_event_id
                    )
                  )
              AND e.event_hour <= v.expires_hour
              AND (
                    v.next_received_event_id IS NULL
                    OR e.event_hour < v.next_received_hour
                    OR (
                        e.event_hour = v.next_received_hour
                        AND e.event_id < v.next_received_event_id
                    )
                  )
            ORDER BY e.event_hour, e.event_id
            LIMIT 1
        ) AS qualified_completed_event_id
    FROM view_details AS v
)
INSERT INTO offer_exposure (
    exposure_id,
    customer_id,
    offer_id,
    received_hour,
    expires_hour,
    next_received_event_id,
    next_received_hour,
    viewed_event_id,
    viewed_hour,
    completed_event_id,
    completed_hour,
    qualified_completed_event_id,
    qualified_completed_hour,
    was_viewed,
    was_completed_in_window,
    was_completed_after_view
)
SELECT
    m.exposure_id,
    m.customer_id,
    m.offer_id,
    m.received_hour,
    m.expires_hour,
    m.next_received_event_id,
    m.next_received_hour,
    m.viewed_event_id,
    m.viewed_hour,
    m.completed_event_id,
    completed.event_hour,
    m.qualified_completed_event_id,
    qualified.event_hour,
    CASE WHEN m.viewed_event_id IS NULL THEN 0 ELSE 1 END,
    CASE WHEN m.completed_event_id IS NULL THEN 0 ELSE 1 END,
    CASE WHEN m.qualified_completed_event_id IS NULL THEN 0 ELSE 1 END
FROM matched_completions AS m
LEFT JOIN transcript_event AS completed
    ON completed.event_id = m.completed_event_id
LEFT JOIN transcript_event AS qualified
    ON qualified.event_id = m.qualified_completed_event_id;

CREATE INDEX idx_offer_exposure_customer_offer
    ON offer_exposure(customer_id, offer_id, received_hour);

CREATE INDEX idx_offer_exposure_offer_outcome
    ON offer_exposure(offer_id, was_viewed, was_completed_after_view);

CREATE VIEW vw_customer_offer_funnel AS
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

CREATE VIEW vw_offer_performance AS
SELECT
    p.offer_id,
    p.offer_type,
    p.offer_type_label,
    p.reward,
    p.difficulty,
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
        1.0 * COALESCE(SUM(f.viewed_count), 0) /
        NULLIF(COALESCE(SUM(f.received_count), 0), 0),
        4
    ) AS view_rate,
    ROUND(
        1.0 * COALESCE(SUM(f.completed_after_view_count), 0) /
        NULLIF(COALESCE(SUM(f.received_count), 0), 0),
        4
    ) AS qualified_completion_rate_from_received,
    ROUND(
        1.0 * COALESCE(SUM(f.completed_after_view_count), 0) /
        NULLIF(COALESCE(SUM(f.viewed_count), 0), 0),
        4
    ) AS qualified_completion_rate_from_viewed
FROM portfolio AS p
LEFT JOIN vw_customer_offer_funnel AS f
    ON f.offer_id = p.offer_id
GROUP BY
    p.offer_id,
    p.offer_type,
    p.offer_type_label,
    p.reward,
    p.difficulty,
    p.duration_days,
    p.channel_web,
    p.channel_email,
    p.channel_mobile,
    p.channel_social;

-- ---------------------------------------------------------------------------
-- 6. Quality summary
-- ---------------------------------------------------------------------------

CREATE TABLE data_quality_summary (
    metric_name         TEXT PRIMARY KEY,
    metric_value        INTEGER NOT NULL,
    status              TEXT NOT NULL CHECK (status IN ('PASS', 'WARNING', 'FAIL')),
    notes               TEXT NOT NULL
);

INSERT INTO data_quality_summary VALUES
(
    'raw_portfolio_rows',
    (SELECT COUNT(*) FROM raw_portfolio),
    'PASS',
    'Rows loaded from portfolio.csv.'
),
(
    'clean_portfolio_rows',
    (SELECT COUNT(*) FROM portfolio),
    CASE
        WHEN (SELECT COUNT(*) FROM portfolio) = (SELECT COUNT(*) FROM raw_portfolio)
        THEN 'PASS' ELSE 'FAIL'
    END,
    'Offers retained after validation.'
),
(
    'raw_profile_rows',
    (SELECT COUNT(*) FROM raw_profile),
    'PASS',
    'Rows loaded from profile.csv.'
),
(
    'clean_profile_rows',
    (SELECT COUNT(*) FROM customer_profile),
    CASE
        WHEN (SELECT COUNT(*) FROM customer_profile) = (SELECT COUNT(*) FROM raw_profile)
        THEN 'PASS' ELSE 'FAIL'
    END,
    'Customer profiles retained after validation.'
),
(
    'raw_transcript_rows',
    (SELECT COUNT(*) FROM raw_transcript),
    'PASS',
    'Rows loaded from transcript.csv.'
),
(
    'clean_transcript_rows',
    (SELECT COUNT(*) FROM transcript_event),
    CASE
        WHEN (SELECT COUNT(*) FROM transcript_event) = (SELECT COUNT(*) FROM raw_transcript)
        THEN 'PASS' ELSE 'FAIL'
    END,
    'Events retained after validation.'
),
(
    'hard_validation_errors',
    (SELECT COUNT(*) FROM etl_error_log WHERE severity = 'ERROR'),
    CASE
        WHEN (SELECT COUNT(*) FROM etl_error_log WHERE severity = 'ERROR') = 0
        THEN 'PASS' ELSE 'FAIL'
    END,
    'Rows or values that failed a required validation rule.'
),
(
    'profiles_with_imputation',
    (SELECT COUNT(*) FROM customer_profile WHERE profile_status = 'Imputed'),
    CASE
        WHEN (SELECT COUNT(*) FROM customer_profile WHERE profile_status = 'Imputed') = 0
        THEN 'PASS' ELSE 'WARNING'
    END,
    'Profiles with unknown gender and/or median-imputed age or income.'
),
(
    'exact_duplicate_events',
    (SELECT COUNT(*) FROM transcript_event WHERE is_exact_duplicate = 1),
    CASE
        WHEN (SELECT COUNT(*) FROM transcript_event WHERE is_exact_duplicate = 1) = 0
        THEN 'PASS' ELSE 'WARNING'
    END,
    'Repeated events retained with a flag and excluded from the deduplicated view.'
),
(
    'orphan_customer_events',
    (
        SELECT COUNT(*)
        FROM transcript_event AS t
        LEFT JOIN customer_profile AS c ON c.customer_id = t.customer_id
        WHERE c.customer_id IS NULL
    ),
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM transcript_event AS t
            LEFT JOIN customer_profile AS c ON c.customer_id = t.customer_id
            WHERE c.customer_id IS NULL
        ) = 0 THEN 'PASS' ELSE 'FAIL'
    END,
    'Clean events without a matching customer.'
),
(
    'orphan_offer_events',
    (
        SELECT COUNT(*)
        FROM transcript_event AS t
        LEFT JOIN portfolio AS p ON p.offer_id = t.offer_id
        WHERE t.offer_id IS NOT NULL AND p.offer_id IS NULL
    ),
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM transcript_event AS t
            LEFT JOIN portfolio AS p ON p.offer_id = t.offer_id
            WHERE t.offer_id IS NOT NULL AND p.offer_id IS NULL
        ) = 0 THEN 'PASS' ELSE 'FAIL'
    END,
    'Offer-linked clean events without a matching offer.'
),
(
    'offer_exposure_rows',
    (SELECT COUNT(*) FROM offer_exposure),
    'PASS',
    'One sequence-aware analytical row per deduplicated offer-received event.'
),
(
    'offer_exposure_sequence_errors',
    (
        SELECT COUNT(*)
        FROM offer_exposure
        WHERE (viewed_hour IS NOT NULL AND viewed_hour < received_hour)
           OR (completed_hour IS NOT NULL AND completed_hour < received_hour)
           OR (
                qualified_completed_hour IS NOT NULL
                AND (
                    viewed_hour IS NULL
                    OR qualified_completed_hour < viewed_hour
                )
              )
           OR COALESCE(viewed_hour, received_hour) > expires_hour
           OR COALESCE(completed_hour, received_hour) > expires_hour
           OR COALESCE(qualified_completed_hour, received_hour) > expires_hour
    ),
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM offer_exposure
            WHERE (viewed_hour IS NOT NULL AND viewed_hour < received_hour)
               OR (completed_hour IS NOT NULL AND completed_hour < received_hour)
               OR (
                    qualified_completed_hour IS NOT NULL
                    AND (
                        viewed_hour IS NULL
                        OR qualified_completed_hour < viewed_hour
                    )
                  )
               OR COALESCE(viewed_hour, received_hour) > expires_hour
               OR COALESCE(completed_hour, received_hour) > expires_hour
               OR COALESCE(qualified_completed_hour, received_hour) > expires_hour
        ) = 0 THEN 'PASS' ELSE 'FAIL'
    END,
    'Exposure outcomes must follow receipt/view order and remain within validity.'
),
(
    'offer_rates_over_one',
    (
        SELECT COUNT(*)
        FROM vw_offer_performance
        WHERE view_rate > 1
           OR qualified_completion_rate_from_received > 1
           OR qualified_completion_rate_from_viewed > 1
    ),
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM vw_offer_performance
            WHERE view_rate > 1
               OR qualified_completion_rate_from_received > 1
               OR qualified_completion_rate_from_viewed > 1
        ) = 0 THEN 'PASS' ELSE 'FAIL'
    END,
    'Sequence-aware offer rates must stay between zero and one.'
);

-- Block accidental modification of the raw staging layer after loading.
CREATE TRIGGER raw_portfolio_no_update
BEFORE UPDATE ON raw_portfolio
BEGIN
    SELECT RAISE(ABORT, 'raw_portfolio is immutable');
END;

CREATE TRIGGER raw_portfolio_no_delete
BEFORE DELETE ON raw_portfolio
BEGIN
    SELECT RAISE(ABORT, 'raw_portfolio is immutable');
END;

CREATE TRIGGER raw_profile_no_update
BEFORE UPDATE ON raw_profile
BEGIN
    SELECT RAISE(ABORT, 'raw_profile is immutable');
END;

CREATE TRIGGER raw_profile_no_delete
BEFORE DELETE ON raw_profile
BEGIN
    SELECT RAISE(ABORT, 'raw_profile is immutable');
END;

CREATE TRIGGER raw_transcript_no_update
BEFORE UPDATE ON raw_transcript
BEGIN
    SELECT RAISE(ABORT, 'raw_transcript is immutable');
END;

CREATE TRIGGER raw_transcript_no_delete
BEFORE DELETE ON raw_transcript
BEGIN
    SELECT RAISE(ABORT, 'raw_transcript is immutable');
END;

COMMIT;
