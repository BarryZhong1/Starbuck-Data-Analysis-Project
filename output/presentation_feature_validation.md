# Presentation Feature Validation

## Outcome

All presentation methods are represented by MySQL 8 stored procedures,
their smoke-test calls are present, the clean import files match the
required schemas, and the expected results reconcile to the validated
SQLite analytical database. The raw source hashes remain unchanged.

## Stored-program coverage

| Procedure | Required method | Static contract |
|---|---|:---:|
| `sp_get_all_events` | Stored procedure with no parameters | PASS |
| `sp_gender_percentage_by_age` | One IN parameter | PASS |
| `sp_gender_age_percentage` | Multiple IN parameters | PASS |
| `sp_event_count` | OUT parameter | PASS |
| `sp_customer_count_at_or_above_age` | INOUT parameter | PASS |
| `sp_age_band_summary_while` | WHILE loop | PASS |
| `sp_offer_metrics_repeat` | REPEAT loop | PASS |
| `sp_even_numbers_loop` | LOOP, LEAVE, ITERATE, and MOD | PASS |
| `sp_customer_income_band` | IF / ELSEIF / ELSE | PASS |

## Clean import contract

| File | Rows | Header contract |
|---|---:|:---:|
| `portfolio_clean.csv` | 10 | PASS |
| `customer_profile_clean.csv` | 17,000 | PASS |
| `transcript_event_clean.csv` | 306,534 | PASS |
| `offer_exposure_clean.csv` | 76,277 | PASS |

## Expected smoke-test values

| Check | Expected value | Reconciled |
|---|---:|:---:|
| Deduplicated `offer_completed` events | 33,182 | PASS |
| Customers age 30 or above | 13,251 | PASS |
| Customers age 60 or above | 5,875 | PASS |
| Female customers age 30 or above | 5,691 | PASS |
| Sample customer income | $112,000.00 | PASS |

## Integrity

- SQLite integrity check: `ok`
- Required MySQL procedures: 9 of 9
- Raw source files with matching before/after SHA-256: 3 of 3
- Raw files modified by this validation: 0

The executable MySQL smoke test is `mysql/tests/smoke_test.sql`.
