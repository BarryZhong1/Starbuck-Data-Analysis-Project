CREATE DATABASE IF NOT EXISTS starbucks_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE starbucks_analytics;

CREATE TABLE portfolio (
    offer_id            CHAR(32) PRIMARY KEY,
    offer_type          VARCHAR(20) NOT NULL,
    offer_type_label    VARCHAR(30) NOT NULL,
    reward              INT NOT NULL,
    difficulty          INT NOT NULL,
    duration_days       INT NOT NULL,
    channels_json       JSON NOT NULL,
    channel_web         TINYINT NOT NULL,
    channel_email       TINYINT NOT NULL,
    channel_mobile      TINYINT NOT NULL,
    channel_social      TINYINT NOT NULL,
    channel_count       INT NOT NULL,
    source_row_id       BIGINT NOT NULL UNIQUE,
    CONSTRAINT chk_portfolio_type
        CHECK (offer_type IN ('bogo', 'discount', 'informational')),
    CONSTRAINT chk_portfolio_nonnegative
        CHECK (
            reward >= 0
            AND difficulty >= 0
            AND duration_days > 0
            AND channel_count BETWEEN 1 AND 4
        )
);

CREATE TABLE portfolio_channel (
    offer_id            CHAR(32) NOT NULL,
    channel             VARCHAR(10) NOT NULL,
    PRIMARY KEY (offer_id, channel),
    CONSTRAINT fk_portfolio_channel_offer
        FOREIGN KEY (offer_id) REFERENCES portfolio(offer_id),
    CONSTRAINT chk_portfolio_channel
        CHECK (channel IN ('web', 'email', 'mobile', 'social'))
);

CREATE TABLE customer_profile (
    customer_id         CHAR(32) PRIMARY KEY,
    gender_code         CHAR(1),
    gender_label        VARCHAR(10) NOT NULL,
    age_clean           SMALLINT,
    age_imputed         SMALLINT NOT NULL,
    age_was_imputed     TINYINT NOT NULL,
    membership_date     DATE NOT NULL,
    membership_year     SMALLINT NOT NULL,
    income_clean        DECIMAL(12, 2),
    income_imputed      DECIMAL(12, 2) NOT NULL,
    income_was_imputed  TINYINT NOT NULL,
    profile_status      VARCHAR(10) NOT NULL,
    source_row_id       BIGINT NOT NULL UNIQUE,
    CONSTRAINT chk_profile_gender
        CHECK (gender_code IS NULL OR gender_code IN ('F', 'M', 'O')),
    CONSTRAINT chk_profile_age
        CHECK (age_clean IS NULL OR age_clean BETWEEN 18 AND 117),
    CONSTRAINT chk_profile_imputation_flags
        CHECK (
            age_was_imputed IN (0, 1)
            AND income_was_imputed IN (0, 1)
        ),
    CONSTRAINT chk_profile_status
        CHECK (profile_status IN ('Complete', 'Imputed'))
);

CREATE TABLE transcript_event (
    event_id            BIGINT PRIMARY KEY,
    customer_id         CHAR(32) NOT NULL,
    event_type          VARCHAR(30) NOT NULL,
    event_label         VARCHAR(30) NOT NULL,
    value_json          JSON NOT NULL,
    offer_id            CHAR(32),
    amount              DECIMAL(12, 2),
    reward              INT,
    event_hour          INT NOT NULL,
    event_day_number    INT NOT NULL,
    duplicate_rank      INT NOT NULL,
    is_exact_duplicate  TINYINT NOT NULL,
    source_row_id       BIGINT NOT NULL UNIQUE,
    CONSTRAINT fk_transcript_customer
        FOREIGN KEY (customer_id) REFERENCES customer_profile(customer_id),
    CONSTRAINT fk_transcript_offer
        FOREIGN KEY (offer_id) REFERENCES portfolio(offer_id),
    CONSTRAINT chk_transcript_event_type
        CHECK (
            event_type IN (
                'offer_received',
                'offer_viewed',
                'offer_completed',
                'transaction'
            )
        ),
    CONSTRAINT chk_transcript_nonnegative
        CHECK (
            event_hour >= 0
            AND event_day_number >= 0
            AND duplicate_rank >= 1
            AND is_exact_duplicate IN (0, 1)
        )
);

CREATE INDEX idx_transcript_customer_time
    ON transcript_event(customer_id, event_hour, event_id);

CREATE INDEX idx_transcript_offer_event
    ON transcript_event(offer_id, event_type);

CREATE INDEX idx_transcript_customer_event_duplicate
    ON transcript_event(customer_id, event_type, is_exact_duplicate);

CREATE TABLE offer_exposure (
    exposure_id                    BIGINT PRIMARY KEY,
    customer_id                    CHAR(32) NOT NULL,
    offer_id                       CHAR(32) NOT NULL,
    received_hour                  INT NOT NULL,
    expires_hour                   INT NOT NULL,
    next_received_event_id         BIGINT,
    next_received_hour             INT,
    viewed_event_id                BIGINT,
    viewed_hour                    INT,
    completed_event_id             BIGINT,
    completed_hour                 INT,
    qualified_completed_event_id   BIGINT,
    qualified_completed_hour       INT,
    was_viewed                     TINYINT NOT NULL,
    was_completed_in_window        TINYINT NOT NULL,
    was_completed_after_view       TINYINT NOT NULL,
    CONSTRAINT fk_exposure_customer
        FOREIGN KEY (customer_id) REFERENCES customer_profile(customer_id),
    CONSTRAINT fk_exposure_offer
        FOREIGN KEY (offer_id) REFERENCES portfolio(offer_id),
    CONSTRAINT fk_exposure_viewed_event
        FOREIGN KEY (viewed_event_id) REFERENCES transcript_event(event_id),
    CONSTRAINT fk_exposure_completed_event
        FOREIGN KEY (completed_event_id) REFERENCES transcript_event(event_id),
    CONSTRAINT fk_exposure_qualified_event
        FOREIGN KEY (qualified_completed_event_id)
        REFERENCES transcript_event(event_id),
    CONSTRAINT chk_exposure_hours
        CHECK (
            received_hour >= 0
            AND expires_hour >= received_hour
        ),
    CONSTRAINT chk_exposure_flags
        CHECK (
            was_viewed IN (0, 1)
            AND was_completed_in_window IN (0, 1)
            AND was_completed_after_view IN (0, 1)
        )
);

CREATE INDEX idx_offer_exposure_customer_offer
    ON offer_exposure(customer_id, offer_id, received_hour);

CREATE INDEX idx_offer_exposure_offer_outcome
    ON offer_exposure(offer_id, was_viewed, was_completed_after_view);
