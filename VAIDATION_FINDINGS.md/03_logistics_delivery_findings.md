# Logistics & Delivery Analysis — Findings

## On-Time Delivery Rate
- **Finding:** 93.22% of delivered orders arrived on or before the estimated delivery
  date (89,936 of 96,478 delivered orders). 6.77% were late (6,534), and 0.01% (8
  orders) have an unknown delivery date (the known Olist tracking gap).
- **Correction note:** An earlier version of this analysis reported ~91.9%, computed by
  comparing raw timestamp columns without casting to date. Since
  `order_estimated_delivery_date` is stored at midnight while
  `order_delivered_customer_date` carries a real time-of-day, that version
  misclassified some same-day deliveries as late. Caught while rebuilding this measure
  in DAX for Power BI and cross-checking it against SQL — both now agree exactly at
  93.22%, confirming the corrected figure.
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