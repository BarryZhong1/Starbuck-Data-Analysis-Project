# Data Dictionary

## `portfolio`

One typed row per marketing offer.

| Column | Type | Description |
|---|---|---|
| `offer_id` | TEXT | Validated 32-character offer identifier; primary key |
| `offer_type` | TEXT | Canonical code: `bogo`, `discount`, or `informational` |
| `offer_type_label` | TEXT | Display label with standardized capitalization |
| `reward` | INTEGER | Reward value supplied with the offer |
| `difficulty` | INTEGER | Required customer spend |
| `duration_days` | INTEGER | Offer duration in days |
| `channels_json` | TEXT/JSON | Valid JSON array of delivery channels |
| `channel_web` | INTEGER | 1 when web is included, otherwise 0 |
| `channel_email` | INTEGER | 1 when email is included, otherwise 0 |
| `channel_mobile` | INTEGER | 1 when mobile is included, otherwise 0 |
| `channel_social` | INTEGER | 1 when social is included, otherwise 0 |
| `channel_count` | INTEGER | Number of channels in the JSON array |
| `source_row_id` | INTEGER | Original zero-based CSV row identifier |

## `portfolio_channel`

Normalized bridge table with one row per offer/channel pair.

| Column | Type | Description |
|---|---|---|
| `offer_id` | TEXT | Foreign key to `portfolio` |
| `channel` | TEXT | `web`, `email`, `mobile`, or `social` |

## `customer_profile`

One cleaned row per customer. Original missingness is never hidden.

| Column | Type | Description |
|---|---|---|
| `customer_id` | TEXT | Validated 32-character customer identifier; primary key |
| `gender_code` | TEXT | Original normalized code (`F`, `M`, `O`) or NULL |
| `gender_label` | TEXT | `Female`, `Male`, `Other`, or `Unknown` |
| `age_clean` | INTEGER | Valid age; age 118 is converted to NULL |
| `age_imputed` | INTEGER | Clean age or the dataset median (55) |
| `age_was_imputed` | INTEGER | 1 when `age_imputed` uses the median |
| `membership_date` | TEXT/DATE | ISO date converted from source `YYYYMMDD` |
| `membership_year` | INTEGER | Membership year |
| `income_clean` | REAL | Valid source income or NULL |
| `income_imputed` | REAL | Clean income or the dataset median (64,000) |
| `income_was_imputed` | INTEGER | 1 when `income_imputed` uses the median |
| `profile_status` | TEXT | `Complete` or `Imputed` |
| `source_row_id` | INTEGER | Original zero-based CSV row identifier |

## `transcript_event`

One row per source event. All source events remain present; exact repeats are
flagged.

| Column | Type | Description |
|---|---|---|
| `event_id` | INTEGER | Stable one-based event key derived from source row ID |
| `customer_id` | TEXT | Foreign key to `customer_profile` |
| `event_type` | TEXT | Canonical snake-case event code |
| `event_label` | TEXT | Display label with standardized capitalization |
| `value_json` | TEXT/JSON | Normalized valid JSON event payload |
| `offer_id` | TEXT | Expanded offer ID; NULL for transactions |
| `amount` | REAL | Expanded transaction amount; NULL for offer events |
| `reward` | INTEGER | Expanded completion reward; NULL for other events |
| `event_hour` | INTEGER | Hours from the start of the observation period |
| `event_day_number` | INTEGER | Zero-based observation day |
| `duplicate_rank` | INTEGER | Rank within an exact customer/event/value/time group |
| `is_exact_duplicate` | INTEGER | 1 for the second or later exact repeat |
| `source_row_id` | INTEGER | Original zero-based CSV row identifier |

## `offer_exposure`

One analytical row per deduplicated `offer_received` event. This table is
derived from clean events; it does not alter or replace source records.

| Column | Type | Description |
|---|---|---|
| `exposure_id` | INTEGER | Primary key equal to the receipt event ID |
| `customer_id` | TEXT | Foreign key to `customer_profile` |
| `offer_id` | TEXT | Foreign key to `portfolio` |
| `received_hour` | INTEGER | Start of the exposure window |
| `expires_hour` | INTEGER | Receipt hour plus the offer duration |
| `next_received_event_id` | INTEGER | Next receipt of the same customer/offer, when present |
| `next_received_hour` | INTEGER | Hour of the next same-offer receipt |
| `viewed_event_id` | INTEGER | First eligible view event in the exposure window |
| `viewed_hour` | INTEGER | Hour of the matched view |
| `completed_event_id` | INTEGER | First completion in the exposure window, regardless of view |
| `completed_hour` | INTEGER | Hour of that in-window completion |
| `qualified_completed_event_id` | INTEGER | First completion after the matched view |
| `qualified_completed_hour` | INTEGER | Hour of the qualified completion |
| `was_viewed` | INTEGER | 1 when an eligible view was matched |
| `was_completed_in_window` | INTEGER | 1 when any completion was matched in-window |
| `was_completed_after_view` | INTEGER | 1 when completion followed a matched view |

## Audit objects

| Object | Purpose |
|---|---|
| `etl_run` | Pipeline start/end time and status |
| `source_file_audit` | File size, row count, before/after hashes |
| `etl_error_log` | Row-level errors, warnings, rules, and cleaning messages |
| `data_quality_summary` | Compact PASS/WARNING/FAIL metrics |

## Analytical views

| View | Purpose |
|---|---|
| `vw_transcript_event_deduplicated` | Keeps the first row in each exact duplicate group |
| `vw_customer_offer_funnel` | Customer-offer exposure, view, and sequence-qualified completion counts |
| `vw_offer_performance` | Offer-level exposure metrics with rates bounded from 0 to 1 |
| `vw_customer_event_sequence` | Chronological event number within each customer using `ROW_NUMBER()` |
| `vw_customer_spend_rank_by_gender` | Customer transaction metrics and spending rank within gender using `DENSE_RANK()` |
| `vw_customer_running_spend` | Transaction-level cumulative customer spending using `SUM() OVER` |
| `vw_customer_age_distribution` | Customer-level age-band counts and percentages using `COUNT() OVER` |

## MySQL stored procedures

These procedures read the clean MySQL tables loaded from the generated CSV
outputs. They never access or modify the raw CSV files.

| Procedure | Parameters | Output |
|---|---|---|
| `sp_get_all_events` | None | All deduplicated transcript events |
| `sp_gender_percentage_by_age` | `IN p_min_age` | Gender counts and percentages at or above the age |
| `sp_gender_age_percentage` | `IN p_gender_code`, `IN p_min_age` | Selected gender count and percentage |
| `sp_event_count` | `IN p_event_type`, `OUT p_event_count` | One deduplicated event count |
| `sp_customer_count_at_or_above_age` | `INOUT p_age_or_count` | Input age replaced by matching customer count |
| `sp_age_band_summary_while` | Three `IN` parameters | Age-band counts built with `WHILE` |
| `sp_offer_metrics_repeat` | None | Offer-type metrics built with `REPEAT` |
| `sp_even_numbers_loop` | `IN p_max_value` | Even values built with `LOOP`, `ITERATE`, and `LEAVE` |
| `sp_customer_income_band` | `IN p_customer_id` | Income value and `IF`-based band |
