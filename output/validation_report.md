# Validation Report

## Outcome

The pipeline completed successfully. Raw files were unchanged, all source rows were
retained in the clean tables, and no hard validation or foreign-key errors were found.

## Source integrity

| File | Rows | Bytes | SHA-256 unchanged |
|---|---:|---:|:---:|
| portfolio.csv | 10 | 880 | Yes |
| profile.csv | 17,000 | 1,011,814 | Yes |
| transcript.csv | 306,534 | 28,629,682 | Yes |

## Data-quality metrics

| Metric | Value | Status | Notes |
|---|---:|:---:|---|
| exact_duplicate_events | 397 | WARNING | Repeated events retained with a flag and excluded from the deduplicated view. |
| profiles_with_imputation | 2,175 | WARNING | Profiles with unknown gender and/or median-imputed age or income. |
| clean_portfolio_rows | 10 | PASS | Offers retained after validation. |
| clean_profile_rows | 17,000 | PASS | Customer profiles retained after validation. |
| clean_transcript_rows | 306,534 | PASS | Events retained after validation. |
| hard_validation_errors | 0 | PASS | Rows or values that failed a required validation rule. |
| offer_exposure_rows | 76,277 | PASS | One sequence-aware analytical row per deduplicated offer-received event. |
| offer_exposure_sequence_errors | 0 | PASS | Exposure outcomes must follow receipt/view order and remain within validity. |
| offer_rates_over_one | 0 | PASS | Sequence-aware offer rates must stay between zero and one. |
| orphan_customer_events | 0 | PASS | Clean events without a matching customer. |
| orphan_offer_events | 0 | PASS | Offer-linked clean events without a matching offer. |
| raw_portfolio_rows | 10 | PASS | Rows loaded from portfolio.csv. |
| raw_profile_rows | 17,000 | PASS | Rows loaded from profile.csv. |
| raw_transcript_rows | 306,534 | PASS | Rows loaded from transcript.csv. |

## Logged cleaning decisions

| Severity | Rule | Affected rows |
|---|---|---:|
| WARNING | MISSING_INCOME | 2,175 |
| WARNING | MISSING_GENDER | 2,175 |
| WARNING | AGE_SENTINEL_118 | 2,175 |
| WARNING | EXACT_DUPLICATE_EVENT | 397 |

## Imputation

- Age median used: 55
- Income median used: $64,000.00
- Nullable cleaned values and explicit imputation flags remain available.

## CSV exports

| File | Rows |
|---|---:|
| portfolio_clean.csv | 10 |
| portfolio_channel.csv | 33 |
| customer_profile_clean.csv | 17,000 |
| transcript_event_clean.csv | 306,534 |
| offer_exposure_clean.csv | 76,277 |
| etl_error_log.csv | 6,922 |
| data_quality_summary.csv | 14 |
| offer_performance.csv | 10 |
| customer_event_sequence_sample.csv | 60 |
| top_customers_by_gender.csv | 40 |
| customer_running_spend_sample.csv | 40 |
| age_distribution.csv | 7 |
