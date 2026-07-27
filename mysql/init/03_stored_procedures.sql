USE starbucks_analytics;

DELIMITER $$

-- No parameters: equivalent to the presentation's GetAllRecord procedure.
DROP PROCEDURE IF EXISTS sp_get_all_events$$
CREATE PROCEDURE sp_get_all_events()
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    SELECT
        event_id,
        customer_id,
        event_type,
        event_label,
        offer_id,
        amount,
        reward,
        event_hour,
        event_day_number
    FROM vw_transcript_event_deduplicated
    ORDER BY event_id;
END$$

-- One IN parameter: gender mix at or above a chosen age.
DROP PROCEDURE IF EXISTS sp_gender_percentage_by_age$$
CREATE PROCEDURE sp_gender_percentage_by_age(IN p_min_age INT)
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_total_customers BIGINT DEFAULT 0;

    IF p_min_age IS NULL OR p_min_age < 0 OR p_min_age > 120 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'p_min_age must be between 0 and 120';
    END IF;

    SELECT COUNT(*)
    INTO v_total_customers
    FROM customer_profile
    WHERE age_clean >= p_min_age;

    SELECT
        gender_code,
        COUNT(*) AS gender_count,
        v_total_customers AS all_customers,
        ROUND(100.0 * COUNT(*) / NULLIF(v_total_customers, 0), 2)
            AS percentage
    FROM customer_profile
    WHERE age_clean >= p_min_age
    GROUP BY gender_code
    ORDER BY gender_code;
END$$

-- Multiple IN parameters: one gender's share above an age threshold.
DROP PROCEDURE IF EXISTS sp_gender_age_percentage$$
CREATE PROCEDURE sp_gender_age_percentage(
    IN p_gender_code VARCHAR(10),
    IN p_min_age INT
)
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_gender_code CHAR(1);
    DECLARE v_total_customers BIGINT DEFAULT 0;

    SET v_gender_code = UPPER(TRIM(p_gender_code));

    IF v_gender_code IS NULL OR v_gender_code NOT IN ('F', 'M', 'O') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'p_gender_code must be F, M, or O';
    END IF;

    IF p_min_age IS NULL OR p_min_age < 0 OR p_min_age > 120 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'p_min_age must be between 0 and 120';
    END IF;

    SELECT COUNT(*)
    INTO v_total_customers
    FROM customer_profile
    WHERE age_clean >= p_min_age;

    SELECT
        v_gender_code AS gender_code,
        COUNT(*) AS gender_count,
        v_total_customers AS all_customers,
        ROUND(100.0 * COUNT(*) / NULLIF(v_total_customers, 0), 2)
            AS percentage
    FROM customer_profile
    WHERE gender_code = v_gender_code
      AND age_clean >= p_min_age;
END$$

-- OUT parameter: return the deduplicated count for a chosen event type.
DROP PROCEDURE IF EXISTS sp_event_count$$
CREATE PROCEDURE sp_event_count(
    IN p_event_type VARCHAR(30),
    OUT p_event_count BIGINT
)
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_event_type VARCHAR(30);

    SET v_event_type = LOWER(REPLACE(TRIM(p_event_type), ' ', '_'));

    IF v_event_type NOT IN (
        'offer_received',
        'offer_viewed',
        'offer_completed',
        'transaction'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unsupported event type';
    END IF;

    SELECT COUNT(*)
    INTO p_event_count
    FROM vw_transcript_event_deduplicated
    WHERE event_type = v_event_type;
END$$

-- INOUT parameter: accept a minimum age and replace it with the customer count.
DROP PROCEDURE IF EXISTS sp_customer_count_at_or_above_age$$
CREATE PROCEDURE sp_customer_count_at_or_above_age(
    INOUT p_age_or_count BIGINT
)
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_min_age INT;

    SET v_min_age = CAST(p_age_or_count AS SIGNED);

    IF v_min_age IS NULL OR v_min_age < 0 OR v_min_age > 120 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Initial INOUT value must be an age from 0 to 120';
    END IF;

    SELECT COUNT(*)
    INTO p_age_or_count
    FROM customer_profile
    WHERE age_clean >= v_min_age;
END$$

-- WHILE: build a parameterized age-band summary.
DROP PROCEDURE IF EXISTS sp_age_band_summary_while$$
CREATE PROCEDURE sp_age_band_summary_while(
    IN p_start_age INT,
    IN p_end_age INT,
    IN p_step INT
)
MODIFIES SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_lower_age INT;
    DECLARE v_upper_age INT;

    IF p_start_age IS NULL
       OR p_end_age IS NULL
       OR p_step IS NULL
       OR p_start_age < 0
       OR p_end_age > 120
       OR p_start_age > p_end_age
       OR p_step <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Use 0 <= start <= end <= 120 and step > 0';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_age_band_summary;
    CREATE TEMPORARY TABLE tmp_age_band_summary (
        age_from INT NOT NULL,
        age_to INT NOT NULL,
        customer_count BIGINT NOT NULL,
        PRIMARY KEY (age_from, age_to)
    );

    SET v_lower_age = p_start_age;

    WHILE v_lower_age <= p_end_age DO
        SET v_upper_age = LEAST(v_lower_age + p_step - 1, p_end_age);

        INSERT INTO tmp_age_band_summary (age_from, age_to, customer_count)
        SELECT
            v_lower_age,
            v_upper_age,
            COUNT(*)
        FROM customer_profile
        WHERE age_clean BETWEEN v_lower_age AND v_upper_age;

        SET v_lower_age = v_lower_age + p_step;
    END WHILE;

    SELECT age_from, age_to, customer_count
    FROM tmp_age_band_summary
    ORDER BY age_from;
END$$

-- REPEAT: calculate one metric row for every offer type.
DROP PROCEDURE IF EXISTS sp_offer_metrics_repeat$$
CREATE PROCEDURE sp_offer_metrics_repeat()
MODIFIES SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_index INT DEFAULT 0;
    DECLARE v_offer_type_count INT DEFAULT 0;
    DECLARE v_offer_type VARCHAR(20);

    DROP TEMPORARY TABLE IF EXISTS tmp_offer_type_metrics;
    CREATE TEMPORARY TABLE tmp_offer_type_metrics (
        offer_type VARCHAR(20) PRIMARY KEY,
        offer_count BIGINT NOT NULL,
        average_difficulty DECIMAL(10, 2) NOT NULL,
        average_reward DECIMAL(10, 2) NOT NULL
    );

    SELECT COUNT(DISTINCT offer_type)
    INTO v_offer_type_count
    FROM portfolio;

    IF v_offer_type_count > 0 THEN
        REPEAT
            SELECT offer_type
            INTO v_offer_type
            FROM portfolio
            GROUP BY offer_type
            ORDER BY offer_type
            LIMIT v_index, 1;

            INSERT INTO tmp_offer_type_metrics (
                offer_type,
                offer_count,
                average_difficulty,
                average_reward
            )
            SELECT
                offer_type,
                COUNT(*),
                ROUND(AVG(difficulty), 2),
                ROUND(AVG(reward), 2)
            FROM portfolio
            WHERE offer_type = v_offer_type
            GROUP BY offer_type;

            SET v_index = v_index + 1;
        UNTIL v_index >= v_offer_type_count
        END REPEAT;
    END IF;

    SELECT
        offer_type,
        offer_count,
        average_difficulty,
        average_reward
    FROM tmp_offer_type_metrics
    ORDER BY offer_type;
END$$

-- LOOP: demonstrate LOOP, LEAVE, ITERATE, MOD, and IF with even values.
DROP PROCEDURE IF EXISTS sp_even_numbers_loop$$
CREATE PROCEDURE sp_even_numbers_loop(IN p_max_value INT)
MODIFIES SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_number INT DEFAULT 0;

    IF p_max_value IS NULL OR p_max_value < 1 OR p_max_value > 1000 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'p_max_value must be between 1 and 1000';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_even_numbers;
    CREATE TEMPORARY TABLE tmp_even_numbers (
        even_value INT PRIMARY KEY
    );

    even_number_loop: LOOP
        SET v_number = v_number + 1;

        IF v_number > p_max_value THEN
            LEAVE even_number_loop;
        END IF;

        IF MOD(v_number, 2) = 1 THEN
            ITERATE even_number_loop;
        END IF;

        INSERT INTO tmp_even_numbers (even_value)
        VALUES (v_number);
    END LOOP;

    SELECT even_value
    FROM tmp_even_numbers
    ORDER BY even_value;
END$$

-- IF / ELSEIF / ELSE: classify one customer's non-imputed income.
DROP PROCEDURE IF EXISTS sp_customer_income_band$$
CREATE PROCEDURE sp_customer_income_band(IN p_customer_id CHAR(32))
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_customer_exists INT DEFAULT 0;
    DECLARE v_income DECIMAL(12, 2);
    DECLARE v_income_band VARCHAR(20);

    SELECT COUNT(*), MAX(income_clean)
    INTO v_customer_exists, v_income
    FROM customer_profile
    WHERE customer_id = p_customer_id;

    IF v_customer_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Customer ID was not found';
    ELSEIF v_income IS NULL THEN
        SET v_income_band = 'unknown_income';
    ELSEIF v_income <= 60000 THEN
        SET v_income_band = 'low_income';
    ELSEIF v_income <= 100000 THEN
        SET v_income_band = 'medium_income';
    ELSE
        SET v_income_band = 'high_income';
    END IF;

    SELECT
        p_customer_id AS customer_id,
        v_income AS income_clean,
        v_income_band AS income_band;
END$$

DELIMITER ;
