---- magnitude and percentage  of delivery status :  late, on time/early , unknown ----
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


