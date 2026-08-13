# Logistics & Delivery Analysis — Findings

## On-Time Delivery Rate
- **Finding:** ~91.9% of delivered orders arrived on or before the estimated delivery
  date.
- **Finding:** For the late orders, average delay is ~8.9 days.

## Orders That Never Reached "Delivered"
- **Finding:** ~3% of orders (and ~3.7% of revenue) never reached delivered status,
  despite having real payment value attached.
- **Interpretation:** These are not simply cancelled-and-refunded orders — real money
  was collected on orders that didn't complete the delivery lifecycle. Worth flagging
  as an operational leak, not just a data quirk.

## Delivery Delay vs. Review Score
- **Finding:** Late orders show an average review score roughly 2 stars lower than
  on-time orders.
- **Finding:** Review scores for late orders are bimodal (cluster at 1-star and
  5-star) rather than following a smooth distribution — customers who receive a late
  order react in two extremes rather than a moderate "slightly annoyed" middle ground.
- **Interpretation:** Lateness is a strong individual driver of dissatisfaction, but
  the bimodal shape suggests other factors (communication, product quality, partial
  refunds, etc.) determine whether a late order still ends in forgiveness (5-star) or
  outright anger (1-star).
