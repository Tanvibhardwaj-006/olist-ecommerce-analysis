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
