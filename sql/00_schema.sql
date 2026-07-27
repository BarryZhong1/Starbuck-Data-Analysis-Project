PRAGMA foreign_keys = ON;
PRAGMA journal_mode = DELETE;

CREATE TABLE etl_run (
    run_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at          TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at        TEXT,
    status              TEXT NOT NULL CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
    raw_directory       TEXT NOT NULL,
    database_version    TEXT NOT NULL
);

CREATE TABLE source_file_audit (
    run_id              INTEGER NOT NULL REFERENCES etl_run(run_id),
    file_name           TEXT NOT NULL,
    row_count           INTEGER NOT NULL CHECK (row_count >= 0),
    size_bytes          INTEGER NOT NULL CHECK (size_bytes >= 0),
    sha256_before       TEXT NOT NULL,
    sha256_after        TEXT,
    source_unchanged    INTEGER CHECK (source_unchanged IN (0, 1)),
    PRIMARY KEY (run_id, file_name)
);

CREATE TABLE etl_error_log (
    error_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id              INTEGER NOT NULL REFERENCES etl_run(run_id),
    severity            TEXT NOT NULL CHECK (severity IN ('ERROR', 'WARNING')),
    source_table        TEXT NOT NULL,
    source_row_id       INTEGER,
    column_name         TEXT,
    raw_value           TEXT,
    rule_code           TEXT NOT NULL,
    message             TEXT NOT NULL,
    logged_at           TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_etl_error_rule
    ON etl_error_log(run_id, severity, rule_code);

-- Raw staging columns intentionally use TEXT. Type conversion happens only in
-- the clean layer, so malformed source values can be logged rather than lost.
CREATE TABLE raw_portfolio (
    source_row_id       INTEGER PRIMARY KEY,
    reward              TEXT,
    channels            TEXT,
    difficulty          TEXT,
    duration            TEXT,
    offer_type          TEXT,
    id                  TEXT
);

CREATE TABLE raw_profile (
    source_row_id       INTEGER PRIMARY KEY,
    gender              TEXT,
    age                 TEXT,
    id                  TEXT,
    became_member_on    TEXT,
    income              TEXT
);

CREATE TABLE raw_transcript (
    source_row_id       INTEGER PRIMARY KEY,
    person              TEXT,
    event               TEXT,
    value               TEXT,
    time                TEXT
);
