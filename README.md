# Olist E-Commerce Analysis

## Project Overview
Analysis of Brazilian e-commerce data to understand sales performance, customer behavior, and logistics efficiency.

**Dataset:** Brazilian E-Commerce Public Dataset by Olist (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Data Structure
- 99,441 orders- from Sept 2016 – Oct 2018
- 96,096 unique customers
- 32,951 products -  across 71 categories
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
- Geographic value by state

### 3. Sales Performance (In Progress)
- Top product categories by revenue
- Top sellers by revenue

### 4. Logistics & Delivery (Planned)
- On-time delivery rates
- Delivery time by state

### 5. Customer Satisfaction (Planned)
- Review score distribution
- Impact of delivery delays on satisfaction

## Tools Used
- **Database:** PostgreSQL
- **SQL Analysis:** Custom queries
- **Visualization:** Power BI (in progress)
- **Version Control:** Git/GitHub

## Key Findings So Far
- 96.88% of customers are one-time buyers (very low loyalty)
- Rural states have higher average order value than urban states
- More analysis coming...

## Next Steps
1. Complete sales performance analysis
2. Analyze logistics efficiency and delivery delays
3. Build Power BI dashboard
4. Create final business recommendations

---
NAME: Tanvi Bhardwaj 
Last Updated: 1/7/2026
