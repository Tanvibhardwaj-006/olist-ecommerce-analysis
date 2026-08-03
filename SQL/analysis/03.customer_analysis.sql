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

---- AOV  avg revenue by each customer  by state :  average spending per order by state

SELECT c.customer_state,
count( DISTINCT o.order_id) AS total_orders,
ROUND(SUM(p.payment_value) )as Total_revenue,
ROUND(avg(p.payment_value)) as Avg_order_value
FROM orders AS O
JOIN customers AS c 
on c.customer_id=o.customer_id
JOIN payments as p 
on o.order_id=p.order_id
group by c.customer_state
order by Avg_order_value;

---  Average item  price : which states are spending more on average per item purchased

SELECT c.customer_state,round(avg(oi.price),2) as avg_item_price
from orders as o  join customers as c 
on o.customer_id = c.customer_id
join order_items  as oi on
o.order_id = oi.order_id
group by c.customer_state 
order by avg_item_price;

---- Items per order by state : which states are buying more items per order on average
SELECT c.customer_state ,
round(count(oi.order_item_id)/count(distinct o.order_id)::numeric,2 )  as  item_per_order
from customers as c 
JOIN orders as o 
on c.customer_id = o.customer_id 
JOIN order_items as oi on
o.order_id = oi.order_id
group by c.customer_state
order by item_per_order; 

/*FINDINGS : rural states show higher AOV and higher average item price. 
despite having far less orders the items per sorder is nearly the same across all states (1.08-1.21).
this tells that rural people spend more likely due to the less seller/product competition in their area. 
*/

--- RMF : REDUENCY, FREQUENCY, MONETARY VALUE :  RFM analysis to identify the most valuable customers

-- recency : the number of days since the last order was placed by each customer
with recency as (
	select  c.customer_unique_id , max(cast(o.order_purchase_timestamp as date)) as last_customer_order_date
	from customers as c 
	join orders as o 
	on c.customer_id = o.customer_id
	group by c.customer_unique_id),
	
reference_date as(
	select 
	max(cast(o.order_purchase_timestamp as date)) as last_order_date
	from  orders as o ),
	
Final_recency as(
	select customer_unique_id, (last_order_date - last_customer_order_date )
 	as recency_days from  reference_date  cross join recency ),
 
--- frequency : total number of orders per customer
frequency as (
	SELECT c.customer_unique_id,COUNT(o.order_id) AS order_count
	FROM orders  as o JOIN customers as c 
	ON o.customer_id = c.customer_id
	GROUP BY  c.customer_unique_id ),

--- monetary value : total amount spent by each customer
monetary_value as(
	SELECT c.customer_unique_id,round(SUM(p.payment_value)::numeric,2) AS total_spent
	FROM orders  as o JOIN customers as c
	ON o.customer_id = c.customer_id
	JOIN payments as p 
	ON o.order_id = p.order_id
	GROUP BY c.customer_unique_id),
	

rfm_value as(
select r.customer_unique_id,
	r.recency_days,
	f.order_count,
	coalesce(m.total_spent,0) as monetary_clean 
from Final_recency as r
join frequency as f
on r.customer_unique_id=f.customer_unique_id 
left join monetary_value as m
on r.customer_unique_id=m.customer_unique_id),


rfm_grade as (
select customer_unique_id,
	recency_days,
	order_count,
 	monetary_clean,
	NTILE(5) OVER (ORDER BY recency_days desc) as r_score,
	case 
	when order_count=1 then 1
	when order_count=2 then 2
	when order_count=3 then 3
	when order_count=4 then 4
	when order_count>=5 then  5
	else 1
	end as f_score ,
	NTILE(5) OVER (ORDER BY monetary_clean asc) as m_score
	FROM rfm_value),

--------  customer_scoring --------
select customer_unique_id,
	recency_days,
	order_count,
 	monetary_clean,
	r_score,
	m_score,
CASE
  WHEN r_score >= 4 AND m_score >= 4 THEN 'Gold'
  WHEN r_score >= 4 AND m_score <= 2 THEN 'Potential'
  WHEN r_score <= 2 AND m_score >= 4 THEN 'At Risk'
  WHEN r_score <= 2 AND m_score <= 2 THEN 'lost'
END AS customer_segment
from rfm_grade;

/* F score excluded from segmentation: 
97% of customers have order_count=1, making frequency non-discriminating.*/

 -- new vs returning customers--
 with monthly_trend as(
select o.order_purchase_timestamp, 
min(o.order_purchase_timestamp) over ( partition by c.customer_unique_id) as first_order_date ,
case 
	when o.order_purchase_timestamp = min(o.order_purchase_timestamp) over ( partition by customer_unique_id)
	then 'New Customers'
	else 'Returning Customers'
end as customer_status,
DATE_TRUNC('month',o.order_purchase_timestamp) as order_month
from orders as o join 
customers as c 
on o.customer_id = c.customer_id)
select order_month,customer_status,count(*) from monthly_trend 
GROUP BY order_month, customer_status;


-- FINDING: Returning customer volume grows steadily 2017→2018 but stays small overall,
-- consistent with the 3.12% repeat purchase rate found earlier.
-- Sept/Oct 2018 dip is a dataset artifact (data ends mid-Oct 2018), not a data quality issue.