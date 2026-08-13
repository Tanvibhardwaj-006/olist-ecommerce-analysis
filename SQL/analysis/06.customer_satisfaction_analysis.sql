with ranked_reviews as (
SELECT 
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp desc) AS rn
    FROM order_reviews)
select review_score,
	count(*) as total_orders,
	round(100.0*count(*)/sum(count(*)) over(),2) as perc_of_total
	from ranked_reviews
	where rn=1
	group by review_score
	order by review_score;
--57.77% of all reviews are 5-star, and 4-5 star combined make up ~77% */

with ranked_reviews as(
SELECT 
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp desc) AS rn
    FROM order_reviews
),
rn1 as (
select * from ranked_reviews where rn=1)

select c.product_category_name_english,
		 ROUND(AVG(rn1.review_score), 2) AS avg_review_score,
		 count(*) as total_count,
		 COUNT(DISTINCT o.order_id) AS distinct_orders
		 from rn1
		 join orders  as o on
		 o.order_id=rn1.order_id
		 join order_items as oi on 
		 o.order_id=oi.order_id
		 join products as p 
		 on p.product_id=oi.product_id
		 join category as c
		 on c.product_category_name=p.product_category_name
		 group by c.product_category_name_english
		 having count(*)>100;

-- the actual unique order count is lower than the total count of reviews for categories with multi-item orders, which is expected.

/* Category-Level Review Attribution Limitation
- **Issue:** order_reviews is recorded per order, not per item/category. Orders with 
  multiple items across different categories cause one review to be counted toward 
  every category present in that order.
- **Impact:** total_count (row-level) > distinct_orders (order-level) for multi-category 
  orders — review scores for affected categories include cross-category noise.
- **Decision:** Retained as-is; no clean split is possible with this schema. 
  distinct_orders column added for transparency alongside total_count*/
  ---"Checked worst-case leakage (signaling_and_security, 142.75% row inflation)
-- — avg_review_score remained consistent with neighboring categories,
-- suggesting leakage does not meaningfully distort category-level averages."


----------------------------------------------------------------------

--- Worst-performing categories despite high order volume--------
WITH ranked_reviews AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (partition by  order_id order by  review_answer_timestamp DESC) AS rn
    FROM order_reviews
),
rn1 AS (
    SELECT * from ranked_reviews where rn = 1
),
category_stats as (
    SELECT c.product_category_name_english,
           round(AVG(rn1.review_score), 2) AS avg_review_score,
           COUNT(*) AS total_count
    FROM rn1
	join  orders o on o.order_id = rn1.order_id
	join  order_items oi on o.order_id = oi.order_id
	join  products p on p.product_id = oi.product_id
	join  category c on c.product_category_name = p.product_category_name
    group by  c.product_category_name_english
   
),
volume_median as (
    select PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_count) AS median_count
    from category_stats
)
SELECT cs.*
from category_stats cs, volume_median vm
where cs.avg_review_score <= 3.9
  	and cs.total_count >= vm.median_count
order by  cs.avg_review_score;
 
--finding: 5 categoies falls under the worst performing categories despite high volume out of which the  OFFICE_FURNITURE
--category stand out the most with avg review score 3.49 below than the other 4 . this category has a real problem in the dataset.

--------------------------------------------------------------------------------------

--Cross-analysis of delivery lateness vs. RFM/recency segments


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
rfm_segment  as (
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
  else 'mid-tier'
END AS customer_segment
from rfm_grade),

deliveries as(
select 
	o.order_id,
	o.order_delivered_customer_date,
	o.order_estimated_delivery_date,
	(o.order_delivered_customer_date:: date - o.order_estimated_delivery_date::date ) as late_days
	from orders as o 
	where o.order_status= 'delivered'
	
),
late_delivery_flag  as (
select dd.order_id,
	case
	when dd.late_days>0 then 'late'
	else 'on time'	end as  late_label
	FROM deliveries as dd)



select customer_segment,
		COUNT(*) FILTER (WHERE late_label = 'late') as late_order,
		count(*) as total_order_count,
		round(100.0*COUNT(*) FILTER (WHERE late_label = 'late')/count(*),2) as '% late'
from rfm_segment  as rfm join 
customers as c on 
rfm.customer_unique_id = c.customer_unique_id
join orders  as o on
o.customer_id=c.customer_id
join late_delivery_flag as ldf on
o.order_id = ldf.order_id
group by customer_segment;