#!/usr/bin/env python3
"""Validate presentation-method coverage and write a concise evidence report."""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sqlite3
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATABASE_PATH = PROJECT_ROOT / "output" / "starbucks_offers.sqlite"
PROCEDURE_PATH = PROJECT_ROOT / "mysql" / "init" / "03_stored_procedures.sql"
SMOKE_TEST_PATH = PROJECT_ROOT / "mysql" / "tests" / "smoke_test.sql"
REPORT_PATH = PROJECT_ROOT / "output" / "presentation_feature_validation.md"

REQUIRED_ROUTINES = {
    "sp_get_all_events": ["CREATE PROCEDURE", "SELECT"],
    "sp_gender_percentage_by_age": ["CREATE PROCEDURE", "IN p_min_age"],
    "sp_gender_age_percentage": [
        "CREATE PROCEDURE",
        "IN p_gender_code",
        "IN p_min_age",
    ],
    "sp_event_count": ["CREATE PROCEDURE", "OUT p_event_count"],
    "sp_customer_count_at_or_above_age": [
        "CREATE PROCEDURE",
        "INOUT p_age_or_count",
    ],
    "sp_age_band_summary_while": [
        "CREATE PROCEDURE",
        "WHILE",
        "END WHILE",
    ],
    "sp_offer_metrics_repeat": [
        "CREATE PROCEDURE",
        "REPEAT",
        "UNTIL",
        "END REPEAT",
    ],
    "sp_even_numbers_loop": [
        "CREATE PROCEDURE",
        "LOOP",
        "LEAVE",
        "ITERATE",
        "MOD(",
        "END LOOP",
    ],
    "sp_customer_income_band": [
        "CREATE PROCEDURE",
        "IF ",
        "ELSEIF",
        "ELSE",
        "END IF",
    ],
}

FEATURE_LABELS = {
    "sp_get_all_events": "Stored procedure with no parameters",
    "sp_gender_percentage_by_age": "One IN parameter",
    "sp_gender_age_percentage": "Multiple IN parameters",
    "sp_event_count": "OUT parameter",
    "sp_customer_count_at_or_above_age": "INOUT parameter",
    "sp_age_band_summary_while": "WHILE loop",
    "sp_offer_metrics_repeat": "REPEAT loop",
    "sp_even_numbers_loop": "LOOP, LEAVE, ITERATE, and MOD",
    "sp_customer_income_band": "IF / ELSEIF / ELSE",
}

EXPECTED_HEADERS = {
    "portfolio_clean.csv": [
        "offer_id",
        "offer_type",
        "offer_type_label",
        "reward",
        "difficulty",
        "duration_days",
        "channels_json",
        "channel_web",
        "channel_email",
        "channel_mobile",
        "channel_social",
        "channel_count",
        "source_row_id",
    ],
    "customer_profile_clean.csv": [
        "customer_id",
        "gender_code",
        "gender_label",
        "age_clean",
        "age_imputed",
        "age_was_imputed",
        "membership_date",
        "membership_year",
        "income_clean",
        "income_imputed",
        "income_was_imputed",
        "profile_status",
        "source_row_id",
    ],
    "transcript_event_clean.csv": [
        "event_id",
        "customer_id",
        "event_type",
        "event_label",
        "value_json",
        "offer_id",
        "amount",
        "reward",
        "event_hour",
        "event_day_number",
        "duplicate_rank",
        "is_exact_duplicate",
        "source_row_id",
    ],
    "offer_exposure_clean.csv": [
        "exposure_id",
        "customer_id",
        "offer_id",
        "received_hour",
        "expires_hour",
        "next_received_event_id",
        "next_received_hour",
        "viewed_event_id",
        "viewed_hour",
        "completed_event_id",
        "completed_hour",
        "qualified_completed_event_id",
        "qualified_completed_hour",
        "was_viewed",
        "was_completed_in_window",
        "was_completed_after_view",
    ],
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_routine_blocks(sql: str) -> dict[str, str]:
    blocks: dict[str, str] = {}
    for chunk in sql.split("$$"):
        match = re.search(
            r"CREATE\s+PROCEDURE\s+([a-z0-9_]+)",
            chunk,
            flags=re.IGNORECASE,
        )
        if match:
            blocks[match.group(1).lower()] = chunk
    return blocks


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main(static_only: bool = False) -> int:
    procedure_sql = PROCEDURE_PATH.read_text(encoding="utf-8")
    smoke_sql = SMOKE_TEST_PATH.read_text(encoding="utf-8")
    blocks = extract_routine_blocks(procedure_sql)

    require(
        set(blocks) == set(REQUIRED_ROUTINES),
        "Stored-procedure set does not match the presentation feature contract",
    )

    feature_rows: list[tuple[str, str, str]] = []
    for routine_name, required_tokens in REQUIRED_ROUTINES.items():
        block_upper = blocks[routine_name].upper()
        missing = [
            token
            for token in required_tokens
            if token.upper() not in block_upper
        ]
        require(
            not missing,
            f"{routine_name} is missing required tokens: {', '.join(missing)}",
        )
        require(
            routine_name in smoke_sql,
            f"{routine_name} is missing from the smoke-test contract",
        )
        feature_rows.append((routine_name, FEATURE_LABELS[routine_name], "PASS"))

    require(
        procedure_sql.count("DELIMITER $$") == 1
        and procedure_sql.count("DELIMITER ;") == 1,
        "MySQL delimiter declarations are incomplete",
    )

    if static_only:
        print(
            "Presentation static contract passed: "
            f"{len(feature_rows)} required procedures"
        )
        return 0

    require(DATABASE_PATH.is_file(), f"Database not found: {DATABASE_PATH}")

    csv_rows: list[tuple[str, int, str]] = []
    for file_name, expected_header in EXPECTED_HEADERS.items():
        path = PROJECT_ROOT / "output" / file_name
        with path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.reader(handle)
            header = next(reader)
            require(header == expected_header, f"Unexpected header in {file_name}")
            count = sum(1 for _ in reader)
        csv_rows.append((file_name, count, "PASS"))

    connection = sqlite3.connect(f"file:{DATABASE_PATH}?mode=ro", uri=True)
    try:
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        require(integrity == "ok", f"SQLite integrity check failed: {integrity}")

        current_hashes = {
            path.name: sha256(path)
            for path in (PROJECT_ROOT / "data" / "raw").glob("*.csv")
        }
        audited_hashes = {
            row[0]: (row[1], row[2], row[3])
            for row in connection.execute(
                """
                SELECT file_name, sha256_before, sha256_after, source_unchanged
                FROM source_file_audit
                WHERE run_id = (SELECT MAX(run_id) FROM etl_run)
                """
            )
        }
        require(
            set(current_hashes) == set(audited_hashes),
            "Raw-file set differs from the latest audit",
        )
        for file_name, current_hash in current_hashes.items():
            before, after, unchanged = audited_hashes[file_name]
            require(
                unchanged == 1 and current_hash == before == after,
                f"Raw-file hash mismatch: {file_name}",
            )

        event_count = connection.execute(
            """
            SELECT COUNT(*)
            FROM vw_transcript_event_deduplicated
            WHERE event_type = 'offer_completed'
            """
        ).fetchone()[0]
        age_30_plus = connection.execute(
            "SELECT COUNT(*) FROM customer_profile WHERE age_clean >= 30"
        ).fetchone()[0]
        age_60_plus = connection.execute(
            "SELECT COUNT(*) FROM customer_profile WHERE age_clean >= 60"
        ).fetchone()[0]
        female_30_plus = connection.execute(
            """
            SELECT COUNT(*)
            FROM customer_profile
            WHERE gender_code = 'F' AND age_clean >= 30
            """
        ).fetchone()[0]
        sample_income = connection.execute(
            """
            SELECT income_clean
            FROM customer_profile
            WHERE customer_id = '0610b486422d4921ae7d2bf64640c50b'
            """
        ).fetchone()[0]
    finally:
        connection.close()

    require(event_count == 33182, "Unexpected offer_completed count")
    require(age_30_plus == 13251, "Unexpected age-30-plus count")
    require(age_60_plus == 5875, "Unexpected age-60-plus count")
    require(female_30_plus == 5691, "Unexpected female age-30-plus count")
    require(sample_income == 112000, "Unexpected sample customer income")

    lines = [
        "# Presentation Feature Validation",
        "",
        "## Outcome",
        "",
        "All presentation methods are represented by MySQL 8 stored procedures,",
        "their smoke-test calls are present, the clean import files match the",
        "required schemas, and the expected results reconcile to the validated",
        "SQLite analytical database. The raw source hashes remain unchanged.",
        "",
        "## Stored-program coverage",
        "",
        "| Procedure | Required method | Static contract |",
        "|---|---|:---:|",
    ]
    lines.extend(
        f"| `{name}` | {method} | {status} |"
        for name, method, status in feature_rows
    )
    lines.extend(
        [
            "",
            "## Clean import contract",
            "",
            "| File | Rows | Header contract |",
            "|---|---:|:---:|",
        ]
    )
    lines.extend(
        f"| `{name}` | {count:,} | {status} |"
        for name, count, status in csv_rows
    )
    lines.extend(
        [
            "",
            "## Expected smoke-test values",
            "",
            "| Check | Expected value | Reconciled |",
            "|---|---:|:---:|",
            f"| Deduplicated `offer_completed` events | {event_count:,} | PASS |",
            f"| Customers age 30 or above | {age_30_plus:,} | PASS |",
            f"| Customers age 60 or above | {age_60_plus:,} | PASS |",
            f"| Female customers age 30 or above | {female_30_plus:,} | PASS |",
            f"| Sample customer income | ${sample_income:,.2f} | PASS |",
            "",
            "## Integrity",
            "",
            "- SQLite integrity check: `ok`",
            "- Required MySQL procedures: 9 of 9",
            "- Raw source files with matching before/after SHA-256: 3 of 3",
            "- Raw files modified by this validation: 0",
            "",
            "The executable MySQL smoke test is `mysql/tests/smoke_test.sql`.",
        ]
    )
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Presentation feature validation passed: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Validate the MySQL presentation-method feature contract."
    )
    parser.add_argument(
        "--static-only",
        action="store_true",
        help="Check SQL procedure coverage without requiring generated data.",
    )
    args = parser.parse_args()
    try:
        raise SystemExit(main(static_only=args.static_only))
    except Exception as exc:
        print(f"Presentation feature validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
