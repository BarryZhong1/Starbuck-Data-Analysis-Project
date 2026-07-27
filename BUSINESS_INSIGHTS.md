# Business insights

## Analytical rule

The source may deliver the same offer to the same customer more than once. A
customer-offer total can therefore attach one view or completion to several
receipts and produce impossible rates above 100%.

This project treats each deduplicated `offer_received` event as a separate
exposure. The eligible interval begins at receipt and ends at the earlier of:

- the offer's stated expiration; or
- the next receipt of that same offer by that customer.

A qualified completion must occur after a matched view within this interval.
The rule is deliberately conservative and does not claim causal lift.

## Funnel

| Outcome | Exposures | Rate from receipt |
|---|---:|---:|
| Received | 76,277 | 100.00% |
| Viewed in the valid exposure window | 56,567 | 74.16% |
| Completed in the exposure window | 33,101 | 43.40% |
| Completed after a recorded view | 23,282 | 30.52% |
| Completed in-window without a prior matched view | 9,819 | 12.87% |

The gap between all in-window completions and qualified completions matters.
Counting all 33,101 completions as offer-influenced would overstate the funnel
by 42.18% relative to the conservative qualified count.

## Offer-type comparison

| Offer type | Received | View rate | Qualified completion from receipt | Qualified completion from view |
|---|---:|---:|---:|---:|
| BOGO | 30,499 | 82.79% | 35.87% | 43.33% |
| Discount | 30,543 | 69.97% | 40.41% | 57.75% |
| Informational | 15,235 | 65.29% | N/A | N/A |

BOGO generated more views, while discounts converted a larger share of both
receipts and views into qualified completions. The funnel suggests that BOGO's
main opportunity is after the view, not at initial engagement.

## Individual offers

- The strongest offer was discount
  `fafdcd668e3743c1bb461111dcafc2a4`: 96.45% viewed and 60.37% qualified
  completion from receipt.
- The strongest BOGO was
  `f19421c1d4aa40978ebb69ca19b0e20d`: 95.21% viewed and 46.41% qualified
  completion from receipt.
- Discount `0b1e1539f2cc45b7b9fa7c272da2e1d7` had the weakest initial funnel:
  34.59% viewed and 16.99% qualified completion from receipt.
- The two informational offers had materially different view rates—80.72% and
  49.86%—which supports testing channel design and creative separately.

## Recommendations

1. Use the strongest discount as the benchmark creative and channel mix for a
   controlled follow-up test.
2. Diagnose BOGO post-view friction: reward requirements, redemption steps, and
   timing are stronger candidates than awareness alone.
3. Separate informational-offer engagement from completion KPIs because these
   offers have no completion event by design.
4. Keep in-window completions without a prior view out of the primary qualified
   conversion KPI.
5. Validate the descriptive patterns with a randomized holdout or uplift model
   before changing campaign allocation.

## Limitations

- The dataset is simulated.
- Event times are hourly rather than exact timestamps.
- A recorded view is evidence of sequence, not proof of causality.
- Transactions have no direct offer key, so revenue is not assigned to an offer.
- Channel comparisons are observational because offers differ on several
  attributes at once.
