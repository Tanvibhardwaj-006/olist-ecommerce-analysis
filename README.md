# Olist E-Commerce Analysis

## Project Overview
Analysis of Brazilian e-commerce data to understand sales performance, customer behavior, and logistics efficiency.

**Dataset:** Brazilian E-Commerce Public Dataset by Olist (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Data Structure
- 99,441 orders from Sept 2016 – Oct 2018
- 96,096 unique customers
- 32,951 products across 71 categories
- 3,096 sellers

## Analysis Completed

### 1. Data Validation
- Row counts, null checks, duplicate detection
- Date/status consistency validation
- Found 8 orders with missing delivery dates (documented in VALIDATION_FINDINGS.md)
- **Status: ✅ Complete**

### 2. Customer Analysis
- Total orders per customer
- Repeat purchase rate: **3.12%** (2,997 of 96,096 customers)
- Geographic value by state - rural states show higher AOV and higher average item price than urban states, despite near-identical items-per-order (1.08–1.21) across all states, pointing to reduced seller/product competition in rural regions rather than bulk buying
- **Status: 🔄 In Progress** (RFM segmentation and new-vs-returning customer trend still pending)

### 3. Sales Performance
- Top product categories by revenue
- Top sellers by revenue
- **Status: 🔄 In Progress**

### 4. Logistics & Delivery
File: `sql/analysis/04_logistics_analysis.sql`

- **On-time delivery rate:** 91.88% of delivered orders arrived on time or early, 8.11% were late, and 0.01% (8 orders) have no recorded delivery date - a known Olist data-tracking gap, not a calculation error.
- **Magnitude of delay:** Late orders average **8.87 days** late, with a worst-case outlier of **188 days**.
- **Delay vs. review score:** Late deliveries average a **2.57-star** review, versus **4.29 stars** for on-time/early deliveries. However, the distribution isn't purely one-sided - even among late orders, ~22% still left a 5-star review, showing delay alone doesn't fully determine customer sentiment; other factors (product quality, communication, refund handling) likely play a role.
- **Delay attribution by category:** After filtering out categories with fewer than 100 orders (to avoid unstable percentages from tiny samples), delay looks fairly systemic rather than concentrated in one clear "problem category." Highest late rates: audio (12.93%), fashion_underwear_beach (12.82%), books_technical (10.94%).
- **Delay attribution by seller:** Two sellers stand out clearly above the rest of the seller base - 30.14% and 26.04% late rates respectively (thresholded at ≥50 orders to keep the percentages statistically meaningful) - flagged as candidates for fulfillment-process review.
- **Status: ✅ Complete**

### 5. Customer Satisfaction (Planned)
- Review score distribution
- Worst-performing categories despite high order volume
- Cross-analysis: does delivery lateness correlate with customer RFM segment/recency? (parked from logistics phase, to be tackled alongside RFM work)

## Tools Used
- **Database:** PostgreSQL (via pgAdmin 4)
- **Editor:** VS Code (SQL files as source of truth; VS Code's PostgreSQL extension had unreliable connections, so queries are copy-pasted into pgAdmin to run)
- **Version Control:** Git/GitHub
- **Visualization:** Power BI (in progress)

## Key Findings So Far
- 96.88% of customers are one-time buyers (very low loyalty)
- Rural states have higher average order value than urban states, driven by per-item price premiums rather than bulk buying
- **91.88% on-time delivery rate**, but the 8.11% that are late run 8.87 days late on average, with some extreme outliers
- **Delivery reliability is a major driver of customer satisfaction** - late orders score nearly 2 full stars lower on average than on-time orders, though a meaningful minority of late-order customers remain unaffected (5-star reviews despite delay)
- A small number of specific sellers show late-delivery rates well above the norm, suggesting targeted operational issues rather than a purely systemic/category-driven problem

## Data Handling Notes
- All logistics/delivery queries are scoped to `order_status = 'delivered'` only - canceled, unavailable, or otherwise unshipped orders are excluded, since "on-time delivery" isn't a meaningful metric for an order that never shipped.
- Review analysis deduplicates 547 orders that had two review rows (keeping the most recent, by `review_answer_timestamp`) to avoid double-counting in averages.
- Category-level delay attribution has a known minor limitation: ~3.25% of orders span multiple product categories, and since delay is tracked at the order level (not per item), those orders' lateness is attributed to every category they touch. Documented rather than "fixed," since the affected share is small.

## Next Steps
1. Complete sales performance analysis
2. Complete customer satisfaction analysis (review distribution, worst categories, RFM-vs-delivery cross-analysis)
3. Finish RFM segmentation and new-vs-returning trend in Customer Analysis
4. Build Power BI dashboard
5. Create final business recommendations

---
NAME: Tanvi Bhardwaj
Last Updated: 8/2/2026
