
# Olist E-Commerce Analysis

## Project Overview
End-to-end SQL analysis of the Olist Brazilian E-Commerce Public Dataset —
~99,441 orders, 96,096 customers, 3,096 sellers, 8 relational tables, Sept 2016–Oct
2018. Built to demonstrate real analytical thinking (validation, business-question
framing, defensible thresholds, honest documentation of limitations) rather than a
tutorial-style walkthrough.

**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Key Findings
- Only 3.12% of customers are repeat buyers — retention is a real, structural
  problem, not noise.
- Rural states pay a genuine per-item price premium (not from bulk buying) — likely
  reduced local seller competition.
- Top ~17 of 74 categories drive ~81% of revenue; top ~17.5% of sellers drive ~80%
  of revenue — seller concentration is tighter than category concentration.
- Late deliveries drop average review score by ~2 stars, with a bimodal (not
  gradual) reaction pattern.
- `office_furniture` is a clear satisfaction outlier — the worst-scoring
  high-volume category in the dataset by a wide margin.
- Delivery lateness is roughly uniform across customer value segments — the data
  does **not** support a simple "late delivery causes churn" story.
- Platform growth is driven almost entirely by new-customer acquisition — even at
  peak monthly volume, returning customers stay a small fraction of that month's 
  activity.

Full findings with methodology, thresholds, and reasoning: see (VALIDATION_FINDINGS.md).

## Analysis Completed
| Phase | Status |
|---|---|
| Data Validation | ✅ Complete — see [VALIDATION_FINDINGS.md](./VALIDATION_FINDINGS.md) |
| Customer Analysis | ✅ Complete — repeat purchase rate, geographic AOV, RFM segmentation, and new-vs-returning monthly trend |
| Sales Performance | ✅ Complete |
| Logistics & Delivery | ✅ Complete |  
| Customer Satisfaction | ✅ Complete — review distribution, worst categories, RFM × delivery-lateness cross-analysis |

## Not Started Yet
- Date dimension table (for Power BI trend analysis)
- Power BI dashboard (star-schema modeling, Power Query, DAX)
- Google Sheets staging
- ER diagram + final repo polish

## Tools Used
- **Database:** PostgreSQL (via pgAdmin 4)
- **Editor:** VS Code (.sql files as source of truth; hybrid copy-paste workflow into
  pgAdmin due to unreliable VS Code Postgres extension connection)
- **Version Control:** Git / GitHub
- **Visualization (planned):** Power BI, Google Sheets

## Repo Structure
```
SQL/schema/          -- table creation
SQL/analysis/         -- all analysis queries by phase
findings/             -- per-phase findings, in plain language
VALIDATION_FINDINGS.md
README.md
```

---
**Author:** Tanvi Bhardwaj
**Last Updated:** August 2026
