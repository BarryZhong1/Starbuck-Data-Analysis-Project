#!/usr/bin/env python3
"""Build and validate the Starbucks offers SQLite portfolio project."""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sqlite3
import sys
from pathlib import Path
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = PROJECT_ROOT / "sql"
EXPECTED_FILES = {
    "portfolio.csv": {
        "table": "raw_portfolio",
        "headers": ["", "reward", "channels", "difficulty", "duration", "offer_type", "id"],
        "columns": ["source_row_id", "reward", "channels", "difficulty", "duration", "offer_type", "id"],
    },
    "profile.csv": {
        "table": "raw_profile",
        "headers": ["", "gender", "age", "id", "became_member_on", "income"],
        "columns": ["source_row_id", "gender", "age", "id", "became_member_on", "income"],
    },
    "transcript.csv": {
        "table": "raw_transcript",
        "headers": ["", "person", "event", "value", "time"],
        "columns": ["source_row_id", "person", "event", "value", "time"],
    },
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def regexp(pattern: str | None, value: object) -> int:
    if pattern is None or value is None:
        return 0
    return int(re.search(pattern, str(value)) is not None)


def normalized_csv_rows(
    path: Path,
    expected_headers: list[str],
) -> Iterable[tuple[object, ...]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        try:
            headers = next(reader)
        except StopIteration as exc:
            raise ValueError(f"{path.name} is empty") from exc

        if headers != expected_headers:
            raise ValueError(
                f"{path.name} headers differ from the expected schema.\n"
                f"Expected: {expected_headers}\n"
                f"Found:    {headers}"
            )

        for line_number, row in enumerate(reader, start=2):
            if len(row) != len(headers):
                raise ValueError(
                    f"{path.name} line {line_number} has {len(row)} fields; "
                    f"expected {len(headers)}"
                )
            normalized: list[object] = []
            for index, value in enumerate(row):
                if index == 0:
                    if not re.fullmatch(r"[0-9]+", value.strip()):
                        raise ValueError(
                            f"{path.name} line {line_number} has invalid source index {value!r}"
                        )
                    normalized.append(int(value))
                else:
                    normalized.append(None if value == "" else value)
            yield tuple(normalized)


def load_raw_file(
    connection: sqlite3.Connection,
    run_id: int,
    path: Path,
    config: dict[str, object],
) -> tuple[int, str]:
    before_hash = sha256(path)
    rows = normalized_csv_rows(path, config["headers"])  # type: ignore[arg-type]
    columns = config["columns"]  # type: ignore[assignment]
    table = str(config["table"])
    placeholders = ", ".join("?" for _ in columns)
    sql = f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})"

    row_count = 0
    batch: list[tuple[object, ...]] = []
    for row in rows:
        batch.append(row)
        row_count += 1
        if len(batch) >= 10_000:
            connection.executemany(sql, batch)
            batch.clear()
    if batch:
        connection.executemany(sql, batch)

    connection.execute(
        """
        INSERT INTO source_file_audit
            (run_id, file_name, row_count, size_bytes, sha256_before)
        VALUES (?, ?, ?, ?, ?)
        """,
        (run_id, path.name, row_count, path.stat().st_size, before_hash),
    )
    return row_count, before_hash


def export_query(
    connection: sqlite3.Connection,
    output_path: Path,
    query: str,
) -> int:
    cursor = connection.execute(query)
    headers = [description[0] for description in cursor.description]
    row_count = 0
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(headers)
        while True:
            rows = cursor.fetchmany(10_000)
            if not rows:
                break
            writer.writerows(rows)
            row_count += len(rows)
    return row_count


def scalar(connection: sqlite3.Connection, query: str) -> int:
    result = connection.execute(query).fetchone()
    if result is None:
        raise RuntimeError(f"Query returned no rows: {query}")
    return int(result[0])


def write_validation_report(
    connection: sqlite3.Connection,
    output_path: Path,
    export_counts: dict[str, int],
) -> None:
    metrics = connection.execute(
        """
        SELECT metric_name, metric_value, status, notes
        FROM data_quality_summary
        ORDER BY
            CASE status WHEN 'FAIL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
            metric_name
        """
    ).fetchall()
    rules = connection.execute(
        """
        SELECT severity, rule_code, COUNT(*) AS affected_rows
        FROM etl_error_log
        GROUP BY severity, rule_code
        ORDER BY
            CASE severity WHEN 'ERROR' THEN 1 ELSE 2 END,
            affected_rows DESC
        """
    ).fetchall()
    audits = connection.execute(
        """
        SELECT file_name, row_count, size_bytes, sha256_before, sha256_after, source_unchanged
        FROM source_file_audit
        ORDER BY file_name
        """
    ).fetchall()
    median_age, median_income = connection.execute(
        """
        SELECT
            MIN(age_imputed) FILTER (WHERE age_was_imputed = 1),
            MIN(income_imputed) FILTER (WHERE income_was_imputed = 1)
        FROM customer_profile
        """
    ).fetchone()

    lines = [
        "# Validation Report",
        "",
        "## Outcome",
        "",
        "The pipeline completed successfully. Raw files were unchanged, all source rows were",
        "retained in the clean tables, and no hard validation or foreign-key errors were found.",
        "",
        "## Source integrity",
        "",
        "| File | Rows | Bytes | SHA-256 unchanged |",
        "|---|---:|---:|:---:|",
    ]
    for file_name, row_count, size_bytes, before, after, unchanged in audits:
        lines.append(
            f"| {file_name} | {row_count:,} | {size_bytes:,} | "
            f"{'Yes' if unchanged and before == after else 'No'} |"
        )

    lines.extend(
        [
            "",
            "## Data-quality metrics",
            "",
            "| Metric | Value | Status | Notes |",
            "|---|---:|:---:|---|",
        ]
    )
    for metric_name, metric_value, status, notes in metrics:
        lines.append(f"| {metric_name} | {metric_value:,} | {status} | {notes} |")

    lines.extend(
        [
            "",
            "## Logged cleaning decisions",
            "",
            "| Severity | Rule | Affected rows |",
            "|---|---|---:|",
        ]
    )
    if rules:
        for severity, rule_code, affected_rows in rules:
            lines.append(f"| {severity} | {rule_code} | {affected_rows:,} |")
    else:
        lines.append("| — | No rows logged | 0 |")

    lines.extend(
        [
            "",
            "## Imputation",
            "",
            f"- Age median used: {int(median_age):,}",
            f"- Income median used: ${float(median_income):,.2f}",
            "- Nullable cleaned values and explicit imputation flags remain available.",
            "",
            "## CSV exports",
            "",
            "| File | Rows |",
            "|---|---:|",
        ]
    )
    for name, count in export_counts.items():
        lines.append(f"| {name} | {count:,} |")

    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_database(raw_dir: Path, output_dir: Path, overwrite: bool) -> Path:
    raw_dir = raw_dir.resolve()
    output_dir = output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    database_path = output_dir / "starbucks_offers.sqlite"

    missing = [name for name in EXPECTED_FILES if not (raw_dir / name).is_file()]
    if missing:
        raise FileNotFoundError(
            f"Missing required raw files in {raw_dir}: {', '.join(missing)}"
        )

    if database_path.exists():
        if not overwrite:
            raise FileExistsError(
                f"{database_path} already exists. Pass --overwrite to replace this generated output."
            )
        database_path.unlink()

    connection = sqlite3.connect(database_path)
    connection.create_function("regexp", 2, regexp, deterministic=True)
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA busy_timeout = 30000")

    try:
        connection.executescript((SQL_DIR / "00_schema.sql").read_text(encoding="utf-8"))
        cursor = connection.execute(
            """
            INSERT INTO etl_run (status, raw_directory, database_version)
            VALUES ('RUNNING', ?, ?)
            """,
            (str(raw_dir), sqlite3.sqlite_version),
        )
        run_id = int(cursor.lastrowid)

        before_hashes: dict[str, str] = {}
        for file_name, config in EXPECTED_FILES.items():
            _, before_hashes[file_name] = load_raw_file(
                connection,
                run_id,
                raw_dir / file_name,
                config,
            )
        connection.commit()

        connection.executescript((SQL_DIR / "01_transform.sql").read_text(encoding="utf-8"))
        connection.executescript(
            (SQL_DIR / "03_window_functions.sql").read_text(encoding="utf-8")
        )

        for file_name, before_hash in before_hashes.items():
            path = raw_dir / file_name
            after_hash = sha256(path)
            connection.execute(
                """
                UPDATE source_file_audit
                SET sha256_after = ?,
                    source_unchanged = CASE WHEN sha256_before = ? THEN 1 ELSE 0 END
                WHERE run_id = ? AND file_name = ?
                """,
                (after_hash, after_hash, run_id, file_name),
            )
            if before_hash != after_hash:
                raise RuntimeError(f"Raw file changed during processing: {path}")

        foreign_key_errors = connection.execute("PRAGMA foreign_key_check").fetchall()
        hard_errors = scalar(
            connection,
            "SELECT COUNT(*) FROM etl_error_log WHERE severity = 'ERROR'",
        )
        failed_metrics = scalar(
            connection,
            "SELECT COUNT(*) FROM data_quality_summary WHERE status = 'FAIL'",
        )
        changed_sources = scalar(
            connection,
            "SELECT COUNT(*) FROM source_file_audit WHERE source_unchanged <> 1",
        )
        if foreign_key_errors or hard_errors or failed_metrics or changed_sources:
            raise RuntimeError(
                "Validation failed: "
                f"foreign_keys={len(foreign_key_errors)}, "
                f"hard_errors={hard_errors}, failed_metrics={failed_metrics}, "
                f"changed_sources={changed_sources}"
            )

        connection.execute(
            """
            UPDATE etl_run
            SET completed_at = CURRENT_TIMESTAMP, status = 'SUCCEEDED'
            WHERE run_id = ?
            """,
            (run_id,),
        )
        connection.commit()

        export_queries = {
            "portfolio_clean.csv": "SELECT * FROM portfolio ORDER BY source_row_id",
            "portfolio_channel.csv": "SELECT * FROM portfolio_channel ORDER BY offer_id, channel",
            "customer_profile_clean.csv": "SELECT * FROM customer_profile ORDER BY source_row_id",
            "transcript_event_clean.csv": "SELECT * FROM transcript_event ORDER BY source_row_id",
            "offer_exposure_clean.csv": (
                "SELECT * FROM offer_exposure ORDER BY exposure_id"
            ),
            "etl_error_log.csv": "SELECT * FROM etl_error_log ORDER BY error_id",
            "data_quality_summary.csv": "SELECT * FROM data_quality_summary ORDER BY metric_name",
            "offer_performance.csv": (
                "SELECT * FROM vw_offer_performance "
                "ORDER BY view_rate DESC, "
                "qualified_completion_rate_from_received DESC"
            ),
            "customer_event_sequence_sample.csv": (
                "WITH sample_customers AS ("
                "    SELECT customer_id "
                "    FROM vw_customer_spend_rank_by_gender "
                "    WHERE spending_rank_within_gender = 1"
                ") "
                "SELECT s.* "
                "FROM vw_customer_event_sequence AS s "
                "JOIN sample_customers AS c "
                "  ON c.customer_id = s.customer_id "
                "WHERE s.customer_event_number <= 15 "
                "ORDER BY s.customer_id, s.customer_event_number"
            ),
            "top_customers_by_gender.csv": (
                "SELECT * "
                "FROM vw_customer_spend_rank_by_gender "
                "WHERE spending_rank_within_gender <= 10 "
                "ORDER BY gender_label, spending_rank_within_gender, customer_id"
            ),
            "customer_running_spend_sample.csv": (
                "WITH sample_customers AS ("
                "    SELECT customer_id "
                "    FROM vw_customer_spend_rank_by_gender "
                "    WHERE spending_rank_within_gender = 1"
                ") "
                "SELECT r.* "
                "FROM vw_customer_running_spend AS r "
                "JOIN sample_customers AS c "
                "  ON c.customer_id = r.customer_id "
                "ORDER BY r.customer_id, r.event_hour, r.event_id"
            ),
            "age_distribution.csv": (
                "SELECT DISTINCT "
                "    age_band_order, "
                "    age_group, "
                "    total_customers_with_known_age, "
                "    age_group_count, "
                "    age_group_percentage "
                "FROM vw_customer_age_distribution "
                "ORDER BY age_band_order"
            ),
        }
        export_counts = {
            name: export_query(connection, output_dir / name, query)
            for name, query in export_queries.items()
        }
        write_validation_report(
            connection,
            output_dir / "validation_report.md",
            export_counts,
        )

        connection.execute("PRAGMA optimize")
        connection.commit()
        return database_path
    except Exception:
        try:
            connection.execute(
                """
                UPDATE etl_run
                SET completed_at = CURRENT_TIMESTAMP, status = 'FAILED'
                WHERE status = 'RUNNING'
                """
            )
            connection.commit()
        except sqlite3.Error:
            pass
        raise
    finally:
        connection.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a clean, validated SQLite database from the Starbucks offer CSV files."
    )
    parser.add_argument(
        "--raw-dir",
        type=Path,
        default=PROJECT_ROOT / "data" / "raw",
        help="Directory containing portfolio.csv, profile.csv, and transcript.csv.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=PROJECT_ROOT / "output",
        help="Directory for the database, clean exports, and validation report.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace an existing generated SQLite database.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        database_path = build_database(args.raw_dir, args.output_dir, args.overwrite)
    except Exception as exc:
        print(f"Pipeline failed: {exc}", file=sys.stderr)
        return 1
    print(f"Pipeline succeeded: {database_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
