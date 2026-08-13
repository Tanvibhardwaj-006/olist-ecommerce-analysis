# Customer Satisfaction Analysis — Findings

## Review Score Distribution (Baseline)
- **Finding:** 57.77% of all reviews are 5-star; 4-and-5-star combined make up ~77%
  of all reviews.
- **Interpretation:** Customers are happy by default on this platform. This baseline
  matters — it's the reference point that makes the delivery-lateness finding hit
  harder (a drop to ~2.57 avg for late orders is a real deviation from a normally
  positive baseline, not just "a low number in isolation").

## Category-Level Review Attribution Limitation
- **Issue:** `order_reviews` is recorded per order, not per item/category. Orders with
  multiple items across different categories cause one review to be counted toward
  every category present in that order.
- **Impact quantified:** Compared `total_count` (row-level, after joining to
  order_items) against `distinct_orders` (true unique order count) per category.
  Worst-case leakage was `signaling_and_security` at 142.75% (row count ~43%
  inflated versus real order count).
- **Decision:** Retained as-is — no clean split is possible with this schema.
  Checked the worst-case category's avg_review_score (4.09) against its neighbors
  (4.15–4.18) and found it unremarkable — leakage does not appear to meaningfully
  distort category-level average scores, even at its worst observed rate.

## Worst-Performing Categories Despite High Volume
- **Thresholds used (tested against actual data, not assumed):**
  - "Bad score" = avg_review_score ≤ 3.9 (checked ≤3.5 first — zero categories
    qualified, so it was tightened to a defensible working cutoff).
  - "High volume" = total_count ≥ median(total_count) across all 71 categories
    (mean/SD was tested first — mean ≈1508, SD ≈2543 — SD exceeding the mean
    confirmed the distribution is heavily right-skewed, so mean+SD was rejected as
    a cutoff in favor of the median).
- **Finding:** 5 categories met both conditions — office_furniture (3.49),
  furniture_living_room (3.90), bed_bath_table (3.90), home_confort (3.83),
  audio (3.83).
- **Headline finding:** `office_furniture` is the clearest, most defensible
  "real problem" category in the dataset — its score (3.49) is well below every
  other flagged category, not just marginally below the cutoff.

## RFM Segment vs. Delivery Lateness (Cross-Analysis)
- **Finding:** Late-delivery rate by customer segment:
  | Segment | Late Rate |
  |---|---|
  | Lost | 4.73% |
  | At Risk | 6.02% |
  | Gold | 6.85% |
  | Potential | 6.37% |
  | Mid-tier | 8.14% |
- **Interpretation:** The spread (4.7%–8.1%) is narrow — delivery lateness looks
  roughly uniform across segments rather than sharply segment-driven.
- **Notable, counter-hypothesis finding:** If late deliveries were a strong driver of
  churn, "At Risk" and "Lost" customers would be expected to show the *highest* late
  rates. Instead, "Gold" customers show a slightly *higher* late rate than "At Risk,"
  and "Lost" customers show the *lowest* late rate of all five segments. This
  contradicts a simple "late delivery → churn" story and suggests lateness alone is
  not the primary driver separating high-value from disengaged customers — other
  factors (price, product quality, category mix) likely matter more.
