-- total number of orders per customer
SELECT c.customer_unique_id,COUNT(o.order_id) AS ORDER_COUNT 
FROM orders  as o JOIN customers as c 
ON o.customer_id = c.customer_id
GROUP BY  c.customer_unique_id 
ORDER BY ORDER_COUNT desc;

--- sum of total no. of orders 
select sum(ORDER_COUNT) from 
(SELECT c.customer_unique_id,COUNT(o.order_id) AS ORDER_COUNT 
FROM orders  as o JOIN customers as c 
ON o.customer_id = c.customer_id
GROUP BY  c.customer_unique_id 
);


-- Repeat customers 
WITH  repeat_customers AS 
	(select c.customer_unique_id,COUNT(o.order_id)
	FROM orders as o join customers as c 
	on o.customer_id=c.customer_id
	group by c.customer_unique_id
	having count(o.order_id)>1)
----% of repeat customers 
--  = total number of repeat orders/ total customers *100
SELECT 
    (SELECT COUNT(*) FROM repeat_customers) AS customers_with_repeat_orders,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM customers) AS total_customers,
    ROUND(100.0 * (SELECT COUNT(*) FROM repeat_customers) / 
          (SELECT COUNT(DISTINCT customer_unique_id) FROM customers), 2)
		  AS repeat_purchase_rate_percent;


 /*Customer retention is critically low — 97% of customers never return. 
 This suggests either poor product quality, weak customer experience, 
or a market dynamic we need to understand better.
*/

---- AOV  avg revenue by each customer  by state

SELECT c.customer_state,
count( DISTINCT o.order_id) AS total_orders,
ROUND(SUM(p.payment_value) )as Total_revenue,
ROUND(avg(p.payment_value)) as Avg_order_value
FROM orders AS O
JOIN customers AS c s
on c.customer_id=o.customer_id
JOIN payments as p 
on o.order_id=p.order_id
group by c.customer_state
order by Avg_order_value;



