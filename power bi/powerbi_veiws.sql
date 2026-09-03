-- clean_reviews: one row per order, deduped (order_reviews has duplicate
-- rows per order_id in source data)
CREATE VIEW clean_reviews AS (
    WITH ranked_reviews AS (
        select 
            order_id,
            review_score,
            review_creation_date,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
        from order_reviews
    )
    select order_id, review_score, review_creation_date
    from ranked_reviews
    WHERE rn = 1
);

-- clean_payments: one row per order, aggregated (payments has multiple
-- rows per order due to installments/split payment types)
CREATE VIEW clean_payments AS (
    select 
        order_id,
        ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value
    from payments
    GROUP BY order_id
);

CREATE VIEW clean_orders AS (
    select o.*, c.customer_unique_id
    from orders AS o
    join customers AS c ON o.customer_id = c.customer_id
);

CREATE VIEW dim_customer AS (
WITH customer_state AS (
    select DISTINCT ON (customer_unique_id) customer_unique_id, customer_state
    from customers
    ORDER BY customer_unique_id, customer_id
),
-- (keep all your recency/frequency/monetary_value/rfm_value/rfm_grade CTEs exactly as they are)

recency AS (
    select c.customer_unique_id, MAX(CAST(o.order_purchase_timestamp AS date)) AS last_customer_order_date
    from customers AS c
    join orders AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
reference_date AS (
    select MAX(CAST(o.order_purchase_timestamp AS date)) AS last_order_date FROM orders AS o
),
final_recency AS (
    select customer_unique_id, (last_order_date - last_customer_order_date) AS recency_days
    from reference_date CROSS JOIN recency
),
frequency AS (
    select c.customer_unique_id, COUNT(o.order_id) AS order_count
    from orders AS o JOIN customers AS c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
monetary_value AS (
    select c.customer_unique_id, ROUND(SUM(p.payment_value)::numeric,2) AS total_spent
    from orders AS o JOIN customers AS c ON o.customer_id = c.customer_id
    join payments AS p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
),
rfm_value AS (
    select r.customer_unique_id, r.recency_days, f.order_count, COALESCE(m.total_spent,0) AS monetary_clean
    from final_recency AS r
    join frequency AS f ON r.customer_unique_id = f.customer_unique_id
    LEFT join monetary_value AS m ON r.customer_unique_id = m.customer_unique_id
),
rfm_grade AS (
    select customer_unique_id, recency_days, order_count, monetary_clean,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        CASE WHEN order_count=1 then 1 WHEN order_count=2 then 2 WHEN order_count=3 then 3
             WHEN order_count=4 then 4 WHEN order_count>=5 then 5 ELSE 1 END AS f_score,
        NTILE(5) OVER (ORDER BY monetary_clean ASC) AS m_score
    from rfm_value
)
SELECT g.customer_unique_id, cs.customer_state, g.recency_days, g.order_count, g.monetary_clean,
    g.r_score, g.m_score,
    CASE when g.r_score>=4 and g.m_score>=4 then 'Gold'
         when g.r_score>=4 and g.m_score<=2 then 'Potential'
         when g.r_score<=2 and g.m_score>=4 then 'At Risk'
         when g.r_score<=2 and g.m_score<=2 then 'lost'
         else 'mid-tier' end as customer_segment
from rfm_grade AS g
join customer_state AS cs ON g.customer_unique_id = cs.customer_unique_id
);


