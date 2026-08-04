# Starbucks Customer Offer Analytics — Findings Report

## Executive Summary

The analysis shows that offer success depends less on the advertised reward alone and more on whether customers notice the offer, can realistically meet its spending threshold, and have enough time to act. Social-enabled campaigns were much more likely to be viewed, but stronger visibility did not create an equally large improvement in post-view completion. Lower-friction discounts performed better than offers with larger rewards but more demanding purchase requirements.

The clearest near-term opportunity is the group of 5,212 customers who viewed at least one offer but never recorded a qualified completion. They demonstrated interest but did not convert. These customers are better candidates for carefully timed reminders, lower purchase thresholds, and behavior-based targeting than customers who consistently ignored offers.

Customer history also matters. Higher-spending and longer-tenured customers completed substantially more offers, while customers with incomplete profiles remained active viewers but rarely completed eligible offers. These patterns support differentiated strategies for established, newly joined, high-value, and low-data customers rather than sending the same promotion to everyone.

## Analysis Scope

The source contains:

| Dataset component | Records |
|---|---:|
| Customer profiles | 17,000 |
| Offer definitions | 10 |
| Transcript events | 306,534 |
| Total source records | 323,544 |
| Sequence-matched offer exposures | 76,277 |

The exposure-level analysis matched each offer receipt to later views and completions only when the events occurred in the correct order, within the offer's validity window, and before the same customer received that offer again. This prevents repeated campaigns from producing impossible conversion rates above 100%.

In this report, **qualified completion** means that a BOGO or discount offer was received, viewed, and then completed within its valid exposure window. Informational offers are excluded from completion-rate denominators because they do not generate completion events.

## Key Findings

### 1. Social-enabled campaigns greatly improved offer visibility

| Channel grouping | View rate |
|---|---:|
| Offers including social | 93.99% |
| Offers without social | 47.18% |
| Difference | +46.81 percentage points |

Offers that included the social channel were almost twice as likely to be viewed. However, the difference in completion after an offer had already been viewed was small. This suggests that social distribution was strongly associated with reach and attention, while the offer's value and requirements played a larger role in whether an interested customer completed it.

**Business implication:** Use social as a reach channel, but evaluate message visibility and offer attractiveness as separate problems. Adding another channel cannot compensate for an offer whose threshold, duration, or value proposition is unappealing.

**Important limitation:** The dataset does not hold all other offer attributes constant, so this is an association rather than proof that the social channel caused the higher view rate.

### 2. A larger reward did not guarantee stronger completion

| Discount design | Qualified completion rate |
|---|---:|
| $2 reward with a $10 threshold | 60.37% |
| $5 reward with a $20 threshold | 16.99% |
| Difference | 43.38 percentage points |

The lower-reward discount produced a much higher qualified completion rate. The more demanding $20 purchase threshold appears to have created more friction than the larger reward could overcome.

**Business implication:** Optimize for an attainable customer action, not the headline reward alone. Lower thresholds may generate better participation and may also reduce the reward cost per completion.

**Recommended test:** Run a controlled experiment that varies one attribute at a time—reward, threshold, or duration—to identify the incremental effect of each design choice.

### 3. Viewed-but-uncompleted customers are the largest recovery audience

| Customer behavior | Customers | Share of customer base |
|---|---:|---:|
| Viewed offers but never qualified | 5,212 | 30.66% |

Almost one-third of customers showed interest by viewing an offer but never produced a qualified completion. This group is more actionable than customers who never viewed an offer because it has already crossed the first engagement barrier.

**Business implication:** Create a recovery journey for high-intent non-completers. Potential actions include a reminder before expiration, a lower-threshold follow-up offer, clearer progress messaging, or a recommendation based on prior transaction behavior.

**Measurement:** Track incremental completion and net margin against a randomized no-reminder holdout group. Do not evaluate the strategy on redemption alone.

### 4. Customer value and offer completion were strongly associated

| Observed-spend group | Qualified completion rate |
|---|---:|
| Highest-spend quartile (Q4) | 64.37% |
| Lowest-spend quartile (Q1) | 5.42% |
| Difference | 58.95 percentage points |

The highest-spending quartile completed qualified offers at nearly 12 times the rate of the lowest-spending quartile. This suggests that established purchasing behavior is a powerful indicator of whether a customer can satisfy an offer's requirements.

**Business implication:** Use prior purchase frequency, recency, and value to select suitable offer thresholds. High-value customers may respond to loyalty or premium offers, while low-spend customers may need smaller, easier first steps.

**Important limitation:** These quartiles were calculated from spending observed in the analyzed period. Using same-period spend as a production targeting feature would introduce leakage. A deployed model must calculate customer value only from activity available before the offer is sent.

### 5. Longer-tenured members showed greater value and engagement

| Membership cohort | Average observed spend | Qualified completion rate |
|---|---:|---:|
| Joined in 2016 | $150.84 | 51.57% |
| Joined in 2018 | $56.74 | 23.73% |

The 2016 cohort generated approximately 2.66 times the average observed spend and had a completion rate 27.84 percentage points higher than the 2018 cohort.

**Business implication:** Separate lifecycle strategies are appropriate. New members may benefit from onboarding offers with low barriers and clear explanations, while mature members may be better suited for loyalty, retention, or higher-value promotions.

**Important limitation:** Newer customers had less time to transact during the dataset's observation window. The result should not be interpreted as proof that tenure itself caused higher spending or completion.

### 6. Incomplete customer profiles were engaged but rarely converted

| Profile group | View rate | Qualified completion rate |
|---|---:|---:|
| Incomplete profiles | 79.01% | 11.90% |

The 2,175 customers with incomplete demographic profiles frequently viewed offers but converted at a much lower rate. Missing demographic information therefore does not mean that the customer is inactive; it may indicate that demographic targeting alone is insufficient for this group.

**Business implication:** Use behavioral features—such as transaction recency, frequency, average order value, channel engagement, and prior offer response—for low-data customers. A small incentive to complete the profile could improve later personalization, but its incremental value should be tested.

### 7. Discount offers required more time to convert than BOGO offers

| Offer type | Average time from view to completion |
|---|---:|
| Discount | 53.04 hours |
| BOGO | 36.07 hours |
| Difference | 16.97 hours |

Customers took about 47% longer to complete discounts after viewing them. This may reflect the need to accumulate more qualifying spend, weaker urgency, or differences in offer design.

**Business implication:** Discount campaigns may need longer validity periods or reminders closer to expiration. BOGO campaigns appear more suitable for shorter, urgency-oriented messaging.

### 8. Repeated exposure showed mild signs of offer fatigue

| Same-offer receipt number | Qualified completion rate |
|---|---:|
| First receipt | 38.33% |
| Third receipt | 35.00% |
| Change | -3.33 percentage points |

Completion declined modestly by the third receipt of the same offer. The decrease is not large enough to justify eliminating repeated campaigns, but it suggests diminishing returns from sending an unchanged offer to the same customer.

**Business implication:** Test frequency caps, creative rotation, or a different offer after two unsuccessful exposures. Because customer and campaign composition may differ across receipt numbers, this pattern should be validated experimentally before changing policy.

### 9. The customer base skews toward middle-aged customers among known profiles

Among the 14,825 customers with known ages, the 50–59 group was the largest segment at 23.89%.

**Business implication:** This segment is large enough to merit dedicated reporting and campaign testing, but population size alone does not establish profitability or responsiveness. Offer decisions should combine age with observed behavior and customer value.

## Recommended Business Actions

1. **Retarget high-intent non-completers.** Prioritize the 5,212 customers who viewed but never qualified, using reminders or lower-friction follow-up offers.
2. **Design around attainable thresholds.** Test lower spending requirements before increasing rewards; evaluate both completion and net promotional cost.
3. **Use channels for their distinct roles.** Use social to improve visibility, then optimize reward, threshold, duration, and message clarity to improve post-view completion.
4. **Adopt lifecycle-based campaigns.** Give new members simple onboarding offers and use loyalty or retention promotions for mature members.
5. **Target incomplete profiles behaviorally.** Avoid excluding customers solely because demographic fields are missing.
6. **Adjust timing by offer type.** Allow more time or send later reminders for discounts; use stronger urgency for BOGO offers.
7. **Control repeated exposure.** Test an offer change or creative refresh after two unsuccessful receipts.
8. **Measure incrementality.** Use randomized holdouts and pre-offer customer history to estimate lift, reward cost, and net margin.

## What the Data Does Not Establish

- Transaction records do not identify which offer caused a purchase, so the analysis does not claim causal revenue attribution.
- The data does not contain a randomized control group; differences between offers or segments are observational.
- Offers vary across multiple attributes, making it unsafe to attribute a performance difference to a single channel, reward, threshold, or duration without an experiment.
- Same-period spending is useful for descriptive segmentation but must not be used as a pre-campaign targeting feature.
- The Starbucks/Udacity data is simulated and should be treated as a portfolio analysis rather than evidence about current Starbucks customers.

## Data Quality and Confidence

- All 323,544 source records reconciled to the analytical pipeline.
- All 76,277 offer exposures passed sequence and validity-window checks.
- No analyzed rate was below 0% or above 100%.
- No hard ETL errors or foreign-key violations were detected.
- SQLite integrity check returned `ok`.
- All three raw-file hashes remained unchanged.
- 397 exact repeated events were retained and flagged rather than silently deleted.
- 2,175 incomplete customer profiles were preserved with explicit missing-data flags.

These controls support reproducibility and traceability, but they do not remove the observational and simulated-data limitations described above.

## Source

[Starbucks Customer Data on Kaggle](https://www.kaggle.com/datasets/ihormuliar/starbucks-customer-data)

