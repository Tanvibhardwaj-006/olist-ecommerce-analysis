# Data Validation & Findings

## What We Checked

We ran a comprehensive validation on the Olist E-Commerce dataset to ensure data quality before analysis. This involved checking 4 things:

### 1. **Completeness** (Did all data import correctly?)
- Checked row counts for each table after import
- Compared against source CSV line counts
- ✅ Result: All 99,441 orders, 96,096 customers, 32,951 products imported successfully

### 2. **Uniqueness** (Are primary/composite keys actually unique?)
- Checked for duplicate values in primary keys: `customer_id`, `order_id`, `product_id`, `seller_id`
- Checked for duplicates in composite keys:
  - `order_items` (order_id + order_item_id)
  - `payments` (order_id + payment_sequential)
  - `order_reviews` (review_id + order_id)
- ✅ Result: All primary and composite keys are unique with zero duplicates

### 3. **Validity** (Do values make logical sense?)

Checked for impossible or unrealistic values:

| Check | Result | Interpretation |
|-------|--------|-----------------|
| Review score outside 1-5 range | 0 rows ✅ | All reviews have valid scores |
| Order items with negative price/freight | 0 rows ✅ | No negative values |
| Payments with negative amount | 0 rows ✅ | All payment amounts are positive |
| Payment installments = 0 | **2 rows ❌** | Bug in source data (invalid installments) |
| Products with weight = 0 | **4 rows ⚠️** | Likely digital products or unmeasured items |
| Products with negative dimensions | 0 rows ✅ | All physical dimensions valid |
| `shipping_limit_date` far outside dataset range | **4 rows ⚠️** | Seller-specific data entry error (see below) |

**What this means:** 2 payment records are corrupted (impossible to pay in 0 installments). 4 products have missing weight data. 4 order_items rows have an implausible shipping_limit_date. These represent <0.01% of the dataset and were kept as-is to preserve data lineage.

### 4. **Consistency** (Do related fields logically match?)

Checked for date/status inconsistencies:

| Check | Result | Interpretation |
|-------|--------|-----------------|
| Delivery date before purchase date (impossible) | 0 rows ✅ | All delivery dates are after purchase |
| Order approved before purchase (impossible) | 0 rows ✅ | All approval dates are after purchase |
| Status = "delivered" but delivery_date is NULL | **8 rows ⚠️** | Known Olist system issue (marked delivered but no date logged) |

**What this means:** 8 orders were marked as "delivered" in the system but the actual delivery date was never recorded. This is a limitation of Olist's order tracking, not a data quality issue we can fix.

---

## Data Quality Summary

| Metric | Status |
|--------|--------|
| **Data Completeness** | 100% (all data imported) |
| **Primary Key Integrity** | ✅ No duplicates |
| **Composite Key Integrity** | ✅ No duplicates |
| **Value Ranges** | ✅ 99.99% valid (12 anomalies documented) |
| **Date Logic** | ✅ Consistent (except 8 known Olist tracking gaps) |
| **Overall Quality** | ✅ ACCEPTABLE FOR ANALYSIS |

---

## Issues Found & How We Handled Them

### 1. Missing Product Categories (During Import)
- **Issue:** 2 product categories existed in products.csv but were missing from the translation table
  - `pc_gamer` (3 products)
  - `portateis_cozinha_e_preparadores_de_alimentos` (10 products)
- **Solution:** Manually added these 2 rows to the categories table with English translations
- **Learning:** Foreign key constraints caught this data quality issue automatically during import

### 2. Payment Installments = 0 (2 records)
- **Issue:** 2 payment records show 0 installments, which is logically impossible
- **Solution:** Documented but retained (we don't own this data; Olist recorded it this way)
- **Impact:** <0.003% of 72,000+ payment records; analysis will not be affected

### 3. Product Weight = 0 (4 records)
- **Issue:** 4 products show weight as 0, likely digital products or data entry errors
- **Solution:** Documented but retained
- **Impact:** <0.01% of 32,951 products; unlikely to affect analysis

### 4. Orders Marked "Delivered" With No Delivery Date (8 records)
- **Issue:** 8 orders have order_status = 'delivered' but order_delivered_customer_date is NULL
- **Solution:** Documented as a known Olist system limitation
- **Impact:** May slightly undercount on-time deliveries, but represents <0.008% of 99,441 orders

### 5. shipping_limit_date Anomaly (4 records, 1 seller)
- **Issue:** 4 `order_items` rows (across 3 orders) have `shipping_limit_date` values in 2020,
  15+ months past the dataset's real order range (Sept 2016–Oct 2018). All 4 rows share the
  same `seller_id`, pointing to a seller-specific data entry error rather than a random or
  systemic issue.
- **Discovered during:** Power BI date dimension setup — `CALENDARAUTO()` picked up this
  outlier and inflated the date table's range to 2020, which is what surfaced the issue.
- **Solution:** Retained in the source table as-is (not our data to correct). Worked around
  at the reporting layer by using explicit `CALENDAR()` bounds (Sept 2016–Oct 2018) instead
  of `CALENDARAUTO()` for the date dimension table.
- **Impact:** None on analysis — this only affected auto-generated date range detection in
  Power BI, not any SQL analysis or metric.

---

## What This Means For Our Analysis

- ✅ The data is reliable enough to analyze
- ✅ These edge cases are too small to materially skew findings
- ✅ We documented everything, so we can explain anomalies if they come up later
- ⚠️ We know 8 orders have incomplete delivery data — noted in logistics analysis
- ⚠️ We know 4 rows have a corrupted future-dated shipping_limit_date tied to one seller —
  noted here and worked around in the Power BI date dimension

**Conclusion:** Data quality is GOOD. We can proceed with confidence to business analysis and dashboarding.
