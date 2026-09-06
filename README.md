# Olist E-Commerce Analysis

End-to-end analytics project on the Brazilian E-Commerce Public Dataset by Olist — SQL analysis through to a 4-page Power BI dashboard. Built to demonstrate real analytical reasoning (validation, correction of my own mistakes, cross-tool verification), not just chart-building.

**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — 99,441 orders, Sept 2016 – Oct 2018, 8 relational tables.

---

## Dashboard Preview

*(screenshots in `/power bi/screenshots`)*

| Overview | Customer Analysis |
|---|---|
| ![Overview](power%20bi/screenshots/overview.png) | ![Customer Analysis](power%20bi/screenshots/customer_analysis.png) |

| Sales Performance | Logistics & Satisfaction |
|---|---|
| ![Sales Performance](power%20bi/screenshots/sales_performance.png) | ![Logistics & Satisfaction](power%20bi/screenshots/logistics_satisfaction.png) |

📊 **[Download the .pbix file](power%20bi/olist_ecommerce_report.pbix)** to explore the full interactive report.

---

## Project Structure

```
├── SQL/
│   ├── 01_create_tables.sql
│   ├── 02_data_validation.sql
│   └── 03_customer_analysis.sql   (+ sales, logistics, satisfaction analysis files)
├── documentation/
│   ├── VALIDATION_FINDINGS.md
│   └── (other findings .md files)
├── power bi/
│   ├── olist_ecommerce_report.pbix
│   └── screenshots/
│       └── (4 dashboard page images)
├── raw data/
│   └── (source CSVs from Kaggle)
├── .gitignore
└── README.md
```

---

## Data Structure

- 99,441 orders across 96,096 unique customers (`customer_unique_id`, distinct from the per-order `customer_id`)
- 32,951 products across 71 categories
- 3,096 sellers
- Geolocation table (1M+ rows) deliberately excluded — scoped out to keep the project focused, documented as a conscious decision rather than an oversight

## Tools Used

- **PostgreSQL** (pgAdmin 4) — all analytical SQL
- **Power BI Desktop** — data model, DAX, 4-page dashboard
- **Git / GitHub** — version control

---

## Analysis Process

### 1. Data Validation
Full 4-category validation: completeness, uniqueness, validity, consistency. Found and documented several small data-quality issues (invalid payment installments, zero-weight products, delivered orders missing delivery dates) — all confirmed too small to affect analysis, all documented rather than silently dropped. Full write-up in `documentation/VALIDATION_FINDINGS.md`.

### 2. Customer Analysis
- Repeat purchase rate calculated at the correct grain (`customer_unique_id`, not `customer_id`)
- RFM segmentation — simplified to R + M scoring after diagnosing that Frequency was unusable (97% of customers have exactly one order, making NTILE-based quartiles meaningless)
- Geographic AOV analysis, verified against item-price and items-per-order to rule out alternate explanations before drawing a conclusion

### 3. Sales Performance
Revenue trend over time, category and seller Pareto analysis (concentration of revenue).

### 4. Logistics
On-time delivery rate, corrected after catching a timestamp-casting bug in the original query (see Key Corrections below). Delay magnitude for late orders isolated separately from the blended average.

### 5. Customer Satisfaction
Review score distribution, worst-performing categories, and a cross-analysis of RFM segment against delivery lateness.

---

## Key Findings

- **Repeat purchase rate: 3.12%** (2,997 of 96,096 customers) — 96.88% of customers never return. Confirmed independently in both SQL and Power BI DAX.
- **On-time delivery rate: 93.22%** — most orders arrive before Olist's estimated delivery date; average delay among *late* orders specifically is **8.87 days**.
- **Late delivery does not clearly drive churn.** Late-delivery rate is roughly uniform (4.7%–8.1%) across all RFM segments, including "At Risk" and "Lost" customers — countering the initial hypothesis that delivery delays are a primary driver of customer loss.
- **Rural states show a genuine price premium, not bulk-buying behavior.** Rural/remote states have meaningfully higher average order value and average item price than urban states, while items-per-order is nearly flat everywhere (1.08–1.21) — ruling out "rural customers buy more per order" as the explanation. Most likely driver: reduced seller/product competition in those regions.
- **Revenue is concentrated**, per both category and seller Pareto analysis — a relatively small share of categories and sellers account for a large share of total revenue.

---

## Key Corrections Made Along the Way

Documenting mistakes and how they were caught matters more than pretending the first pass was always right.

- **On-time delivery rate was initially wrong (91.9%)** due to a missing `::date` cast when comparing delivery timestamps — comparing full datetimes instead of dates was silently misclassifying some on-time orders as late. Corrected to 93.22% after catching it during validation, and documented explicitly rather than quietly fixed.
- **NTILE-based Frequency scoring in RFM was invalid** — 97% of customers have `order_count = 1`, so quartile bucketing produced meaningless segments. Replaced with a fixed CASE-based mapping.
- **DATE_DIM's auto-generated calendar bounds were wrong** (`CALENDARAUTO()` produced an end date of 2020) due to a handful of corrupted `shipping_limit_date` values from one seller. Fixed by explicitly bounding the calendar to the known dataset range instead of trusting auto-detection.
- **A Power BI relationship silently blocked filter propagation** between the category dimension and the payments fact table, causing every category to show the grand total instead of its own revenue. Traced through the relationship chain and fixed by setting the `order_items ↔ orders` relationship to bidirectional cross-filtering.
- **A cumulative-revenue DAX measure caused memory-limit errors** at scale (~3,000 sellers) due to `Total Revenue` being recalculated inside a nested `FILTER`, effectively an O(n²) operation. Fixed by materializing per-seller revenue once with `ADDCOLUMNS` before filtering, instead of recalculating it repeatedly.

---

## Dashboard Pages

1. **Overview** — headline KPIs (revenue, on-time delivery rate, late-order delay, repeat purchase rate) plus a monthly revenue trend
2. **Customer Analysis** — RFM segment sizes (treemap) and average spend per segment
3. **Sales Performance** — revenue trend, and Pareto analysis of revenue concentration by category and by seller
4. **Logistics & Satisfaction** — review score distribution, and delivery delay plotted against average review score by category

---

## Author

**Tanvi Bhardwaj**
