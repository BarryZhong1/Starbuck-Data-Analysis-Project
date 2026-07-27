# Raw data directory

Place the three Kaggle CSV files here before running the pipeline:

- `portfolio.csv`
- `profile.csv`
- `transcript.csv`

The CSVs are intentionally excluded from Git. Download them from the
[Starbucks Customer Data dataset on Kaggle](https://www.kaggle.com/datasets/ihormuliar/starbucks-customer-data/data).
The dataset is simulated and is listed under the
[Community Data License Agreement — Permissive 1.0](https://cdla.dev/permissive-1-0/).

The pipeline opens these files read-only, records SHA-256 hashes before and
after processing, and fails if any source hash changes.
