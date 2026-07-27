from __future__ import annotations

import hashlib
import sqlite3
import tempfile
import unittest
from pathlib import Path

from src.run_pipeline import build_database


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FIXTURE_RAW = PROJECT_ROOT / "tests" / "fixtures" / "raw"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


class PipelineIntegrationTest(unittest.TestCase):
    def test_fixture_pipeline_is_non_destructive_and_sequence_aware(self) -> None:
        source_hashes = {
            path.name: sha256(path)
            for path in sorted(FIXTURE_RAW.glob("*.csv"))
        }

        with tempfile.TemporaryDirectory() as temporary_directory:
            output_dir = Path(temporary_directory)
            database_path = build_database(
                FIXTURE_RAW,
                output_dir,
                overwrite=False,
            )

            self.assertEqual(
                source_hashes,
                {
                    path.name: sha256(path)
                    for path in sorted(FIXTURE_RAW.glob("*.csv"))
                },
            )

            connection = sqlite3.connect(database_path)
            try:
                self.assertEqual(
                    connection.execute("PRAGMA integrity_check").fetchone()[0],
                    "ok",
                )
                self.assertEqual(
                    connection.execute(
                        "SELECT COUNT(*) FROM transcript_event"
                    ).fetchone()[0],
                    10,
                )
                self.assertEqual(
                    connection.execute(
                        """
                        SELECT COUNT(*)
                        FROM transcript_event
                        WHERE is_exact_duplicate = 1
                        """
                    ).fetchone()[0],
                    1,
                )
                self.assertEqual(
                    connection.execute(
                        "SELECT COUNT(*) FROM offer_exposure"
                    ).fetchone()[0],
                    3,
                )

                performance = connection.execute(
                    """
                    SELECT
                        received_count,
                        viewed_count,
                        completed_in_window_count,
                        completed_after_view_count,
                        completed_without_prior_view_count,
                        view_rate,
                        qualified_completion_rate_from_received,
                        qualified_completion_rate_from_viewed
                    FROM vw_offer_performance
                    WHERE offer_id = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                    """
                ).fetchone()
                self.assertEqual(performance, (2, 1, 2, 1, 1, 0.5, 0.5, 1.0))

                failed_metrics = connection.execute(
                    """
                    SELECT COUNT(*)
                    FROM data_quality_summary
                    WHERE status = 'FAIL'
                    """
                ).fetchone()[0]
                self.assertEqual(failed_metrics, 0)

                with self.assertRaisesRegex(
                    sqlite3.DatabaseError,
                    "raw_profile is immutable",
                ):
                    connection.execute(
                        "UPDATE raw_profile SET age = '40' WHERE source_row_id = 0"
                    )
            finally:
                connection.close()


if __name__ == "__main__":
    unittest.main()
