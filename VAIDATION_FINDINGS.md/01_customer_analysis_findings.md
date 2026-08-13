# Customer Analysis — Findings

## Repeat Purchase Rate
- **Finding:** 2,997 of 96,096 unique customers (3.12%) placed more than one order.
- **Interpretation:** 96.88% of customers are one-time buyers. Customer retention is
  critically low — this points to either weak post-purchase experience, low product
  differentiation, or a market where repeat purchase simply isn't the norm for this
  category of e-commerce. Worth flagging as a core business risk.

## Geographic Value (AOV by State)
- **Finding:** Rural/remote states (PB, AL, AC, RO) show meaningfully higher average
  order value (~230–250) than urban states (SP, PR, RS) (~137–155).
- **Follow-up checks:** Confirmed with average item price by state (excluding freight —
  same pattern holds, ruling out a freight artifact) and items-per-order by state
  (nearly flat everywhere, 1.08–1.21 — ruling out "bulk buying" as the explanation).
- **Interpretation:** Rural customers pay a genuine price premium *per item*, most
  likely due to reduced seller/product competition in those regions — not because
  they buy more per order.

## RFM Segmentation
- **Method:** Recency and Monetary scored via `NTILE(5)`. Reference date for Recency
  used `MAX(order_purchase_timestamp)` from the dataset, not `CURRENT_DATE`, since this
  is a frozen historical dataset.
- **Frequency dropped from scoring:** 97% of customers have `order_count = 1`, making
  frequency non-discriminating across the customer base. Using it would add noise, not
  signal, so segmentation was based on Recency + Monetary only. This was a deliberate
  scope decision, not an oversight.
- **Segment sizes:**
  | Segment | Customers |
  |---|---|
  | Gold | 15,866 |
  | Potential | 14,809 |
  | At Risk | 14,956 |
  | Lost | 15,860 |
  | Mid-tier | 34,605 |
- **On the "mid-tier" bucket:** This is the largest single segment (36% of customers).
  This is expected, not a flaw — it captures customers in the middle quintile on
  Recency and/or Monetary, i.e., neither clearly high-value nor clearly disengaged.
  With only the four extreme corners of a 5×5 grid named explicitly, the middle
  naturally absorbs the largest share.

## New vs. Returning Customer Trend Over Time
- **Method:** Classified each order as "new" or "returning" per customer by comparing
  its purchase month to that customer's first-ever order month
  (`MIN() OVER (PARTITION BY customer_unique_id)`), then aggregated counts by month.
- **Finding:** New customer volume grows from near-zero in late 2016 to a stable
  plateau of roughly 6,000–7,000 new customers/month through 2018. Returning
  customers also grow over the same period, but only from single/double digits up to
  roughly 200–250/month at the platform's busiest point.
- **Interpretation:** Even at peak monthly volume, returning customers remain a small
  fraction of that month's activity — this is the monthly-level confirmation of the
  3.12% overall repeat-purchase rate, not a separate or contradicting finding. Growth
  on this platform is being driven almost entirely by new-customer acquisition, not
  retention.
