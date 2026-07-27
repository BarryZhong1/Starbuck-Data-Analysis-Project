# Generated output

Run `python3 src/run_pipeline.py --overwrite` to recreate this directory.

Git tracks only the compact aggregate evidence files used in the portfolio:

- `age_distribution.csv`
- `data_quality_summary.csv`
- `offer_performance.csv`
- `presentation_feature_validation.md`
- `validation_report.md`

The SQLite database and row-level clean exports are generated locally and
ignored because they are large and reproducible from the source data.
