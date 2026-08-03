---- magnitude and percentage  of delivery status :  late, on time/early , unknown ----

-- null check comes first in the case when, otherwise null dates would silently fall into "late"
with delivery_statuses as 
(SELECT
    case 
		when o.order_delivered_customer_date is null then 'Delivery Date Unknown'
		when (o.order_delivered_customer_date = o.order_estimated_delivery_date) 
		or (o.order_delivered_customer_date < o.order_estimated_delivery_date) then 'Delivery on time or early'
		else 'Delivery Late'
		end as  Delivery_status,
    COUNT(*) AS order_count
FROM orders as o
where o.order_status ='delivered' 
GROUP BY Delivery_status )

select ds.Delivery_status,
	ds.order_count,
	round((ds.order_count/ sum(ds.order_count) over())*100,2) as perc_total_delivery
	from  delivery_statuses as ds
	order by ds.Delivery_status;

/* output: on time/early 88,644 (91.88%) | late 7,826 (8.11%) | unknown 8 (0.01%)
the 8 unknown ones match the 8 orders from validation findings - confirms scoping is right */

--- average late delivery days for late deliveries ----


with late_deliveries as(
select 
	o.order_id,
	(o.order_delivered_customer_date:: date - o.order_estimated_delivery_date::date ) as late_days
	from orders as o 
	where o.order_status= 'delivered'
	and order_delivered_customer_date > order_estimated_delivery_date
)
select count(*) as total_late_orders,
		round(avg(late_days),2) as avg_late_days,
		max(late_days) as max_days_late
	from late_deliveries;

/* output: 7,826 late orders | avg 8.87 days late | max 188 days late */
-- row number is assigned the take the most recent review from each order because 
---------AVERAGE REVIEW SCORE -------------------------------------------
WITH ranked_reviews AS (
   SELECT 
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp desc) AS rn
    FROM order_reviews
	
),
delivery_status AS (
    SELECT order_id,
        CASE 
		WHEN o.order_delivered_customer_date is null then 'Delivery Date Unknown'
		when (o.order_delivered_customer_date = o.order_estimated_delivery_date) 
		or (o.order_delivered_customer_date < o.order_estimated_delivery_date) then 'Delivery on time or early'
		else 'Delivery Late'
		END AS delivery_status
    FROM orders as o
    WHERE order_status = 'delivered'
)
SELECT 
    ds.delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(rr.review_score), 2) AS avg_review_score
FROM delivery_status AS ds
JOIN ranked_reviews AS rr ON ds.order_id = rr.order_id
 and rr.rn=1
GROUP BY ds.delivery_status;

/* output: late 2.57 avg score | on time/early 4.29 avg score | unknown 4.50 avg score
late deliveries clearly get worse reviews */


------ delay vs review score----

WITH ranked_reviews AS (
   SELECT 
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp desc) AS rn
    FROM order_reviews
	
),
delivery_status AS (
    SELECT order_id,
        CASE 
		WHEN o.order_delivered_customer_date is null then 'Delivery Date Unknown'
		when (o.order_delivered_customer_date = o.order_estimated_delivery_date) 
		or (o.order_delivered_customer_date < o.order_estimated_delivery_date) then 'Delivery on time or early'
		else 'Delivery Late'
		END AS delivery_status
    FROM orders as o
    WHERE order_status = 'delivered'
)
SELECT 
	 ds.delivery_status,
	rr. review_score,
    COUNT(*) AS total_orders
FROM delivery_status AS ds
JOIN ranked_reviews AS rr ON ds.order_id = rr.order_id
 and rr.rn=1
GROUP BY ds.delivery_status,rr.review_score
order by ds.delivery_status,rr.review_score

/*Of the 7,826 late-delivered orders, the average delay is 8.87 days, with one extreme outlier reaching 188 days late. 
This delay directly translates into customer dissatisfaction: 65.4% of late deliveries received a rating of 3 stars or below, 
compared to just 17.2% among on-time/early deliveries (whose reviews are dominated by 4-5 stars, at 82.8%). 
Delivery reliability is clearly a major driver of customer satisfaction — but the distribution isn't uniform: even among late orders,
~22% still gave 5 stars, suggesting delay alone doesn't fully determine sentiment, 
and other factors (product quality, communication, refund handling) likely play a role too.*/

----- product seller attribution-------

--- PRODUCT ATTRIBUTION-----
-- which product categories have the highest late % (only categories with 100+ orders, else % is unstable)
-- distinct in order_categories so multi-item-same-category orders don't get counted twice
WITH delivery_status AS (
    SELECT order_id,
        CASE 
		WHEN o.order_delivered_customer_date is null then 'Delivery Date Unknown'
		when (o.order_delivered_customer_date = o.order_estimated_delivery_date) 
		or (o.order_delivered_customer_date < o.order_estimated_delivery_date) then 'Delivery on time or early'
		else 'Delivery Late'
		END AS delivery_status
    FROM orders as o
    WHERE order_status = 'delivered'
),
order_categories AS (
    SELECT DISTINCT oi.order_id, c.product_category_name_english
    FROM order_items AS oi
    JOIN products AS p ON oi.product_id = p.product_id
    JOIN category AS c ON p.product_category_name = c.product_category_name
)
SELECT 
    oc.product_category_name_english,
    COUNT(*) AS total_orders,
    SUM(CASE
	WHEN ds.delivery_status = 'Delivery Late' THEN 1 
	ELSE 0 END) AS late_orders,
    ROUND(100.0 * SUM(CASE WHEN ds.delivery_status = 'Delivery Late' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_late
FROM delivery_status AS ds
JOIN order_categories AS oc ON ds.order_id = oc.order_id
GROUP BY oc.product_category_name_english
HAVING COUNT(*) >= 100
ORDER BY pct_late DESC
;
/* output: audio 12.93%, fashion_underwear_beach 12.82%, books_technical 10.94% top the list
no single category is a huge outlier - delay looks spread out, not one category's fault
note: ~3.25% of orders have items across multiple categories,
 so those orders count toward more than one category here - minor, documented, not fixed */


----- SELLER ATTRIBUTION----
-- >=50 threshold instead of 100 - sellers are a much smaller/spread out group than categories, 
--100 wouldve wiped out too many real sellers

WITH delivery_status AS (
    SELECT order_id,
        CASE 
		WHEN o.order_delivered_customer_date is null then 'Delivery Date Unknown'
		when (o.order_delivered_customer_date = o.order_estimated_delivery_date) 
		or (o.order_delivered_customer_date < o.order_estimated_delivery_date) then 'Delivery on time or early'
		else 'Delivery Late'
		END AS delivery_status
    FROM orders as o
    WHERE order_status = 'delivered'
),
order_sellers as (
    SELECT distinct oi.order_id, s.seller_id
    from sellers  as s join order_items  as oi
	on s.seller_id = oi.seller_id
)
SELECT 
    os.seller_id,
    COUNT(*) AS total_orders,
    SUM(case
	when ds.delivery_status = 'Delivery Late' then 1 
	else 0 END) AS late_orders,
    ROUND((SUM(CASE 
    when ds.delivery_status = 'Delivery Late' 
    then  1 
    ELSE 0 END) / COUNT(*))*100, 2) AS pct_late
FROM delivery_status as ds
JOIN order_sellers as os on ds.order_id = os.order_id
group by  os.seller_id
having count(*) >= 50
order by  pct_late DESC
;

/* output: two sellers clearly stand out - 30.14% late (73 orders) and 26.04% late (96 orders)
rest of the list tapers off normally, some sellers even at 0% late on 50-90 orders
unlike categories, this one actually points to specific bad actors - w