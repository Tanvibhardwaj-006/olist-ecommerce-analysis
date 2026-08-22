-- clean_reviews: one row per order, deduped (order_reviews has duplicate
-- rows per order_id in source data)
CREATE VIEW clean_reviews AS (
    WITH ranked_reviews AS (
        SELECT 
            order_id,
            review_score,
            review_creation_date,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
        FROM order_reviews
    )
    SELECT order_id, review_score, review_creation_date
    FROM ranked_reviews
    WHERE rn = 1
);

-- clean_payments: one row per order, aggregated (payments has multiple
-- rows per order due to installments/split payment types)
CREATE VIEW clean_payments AS (
    SELECT 
        order_id,
        ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value
    FROM payments
    GROUP BY order_id
);

CREATE VIEW clean_orders AS (
    SELECT o.*, c.customer_unique_id
    FROM orders AS o
    JOIN customers AS c ON o.customer_id = c.customer_id
);

CREATE VIEW dim_customer AS (
WITH customer_state AS (
    SELECT DISTINCT ON (customer_unique_id) customer_unique_id, customer_state
    FROM customers
    ORDER BY customer_unique_id, customer_id
),
-- (keep all your recency/frequency/monetary_value/rfm_value/rfm_grade CTEs exactly as they are)

recency AS (
    SELECT c.customer_unique_id, MAX(CAST(o.order_purchase_timestamp AS date)) AS last_customer_order_date
    FROM customers AS c
    JOIN orders AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
reference_date AS (
    SELECT MAX(CAST(o.order_purchase_timestamp AS date)) AS last_order_date FROM orders AS o
),
final_recency AS (
    SELECT customer_unique_id, (last_order_date - last_customer_order_date) AS recency_days
    FROM reference_date CROSS JOIN recency
),
frequency AS (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
    FROM orders AS o JOIN customers AS c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
monetary_value AS (
    SELECT c.customer_unique_id, ROUND(SUM(p.payment_value)::numeric,2) AS total_spent
    FROM orders AS o JOIN customers AS c ON o.customer_id = c.customer_id
    JOIN payments AS p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
),
rfm_value AS (
    SELECT r.customer_unique_id, r.recency_days, f.order_count, COALESCE(m.total_spent,0) AS monetary_clean
    FROM final_recency AS r
    JOIN frequency AS f ON r.customer_unique_id = f.customer_unique_id
    LEFT JOIN monetary_value AS m ON r.customer_unique_id = m.customer_unique_id
),
rfm_grade AS (
    SELECT customer_unique_id, recency_days, order_count, monetary_clean,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        CASE WHEN order_count=1 THEN 1 WHEN order_count=2 THEN 2 WHEN order_count=3 THEN 3
             WHEN order_count=4 THEN 4 WHEN order_count>=5 THEN 5 ELSE 1 END AS f_score,
        NTILE(5) OVER (ORDER BY monetary_clean ASC) AS m_score
    FROM rfm_value
)
SELECT g.customer_unique_id, cs.customer_state, g.recency_days, g.order_count, g.monetary_clean,
    g.r_score, g.m_score,
    CASE WHEN g.r_score>=4 AND g.m_score>=4 THEN 'Gold'
         WHEN g.r_score>=4 AND g.m_score<=2 THEN 'Potential'
         WHEN g.r_score<=2 AND g.m_score>=4 THEN 'At Risk'
         WHEN g.r_score<=2 AND g.m_score<=2 THEN 'lost'
         ELSE 'mid-tier' END AS customer_segment
FROM rfm_grade AS g
JOIN customer_state AS cs ON g.customer_unique_id = cs.customer_unique_id
);


