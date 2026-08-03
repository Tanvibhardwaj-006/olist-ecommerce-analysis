--- PERFORMANCE ANALYSIS----

-- Monthly revenue and order volume trend — is the business growing or flattening?
SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    sum( p.payment_value) AS total_revenue,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders AS o
left JOIN payments AS p ON o.order_id = p.order_id
GROUP BY order_month
ORDER BY order_month 


-- FINDING: Order volume and revenue grew steadily through 2017, then plateaued in 2018 
-- (fluctuating 6,100-7,300 orders/month with no clear trend). AOV stayed remarkably stable 
-- (150-170) across the entire dataset, indicating the 2018 plateau is a volume story, 
-- not a customer-spending story. Nov 2017 spike (~7,544 orders) coincides with Black Friday.
-- Sept/Oct 2018 near-zero counts are a dataset cutoff artifact (data ends mid-Oct 2018), not real.


--- REVENUE PER CATEGORY ----
----PARETO ANALYSIS----
with category_revenue as (
SELECT c.product_category_name_english, round(sum(oi.price):: numeric,2) as category_revenue
FROM category as c JOIN  products as p on 
c.product_category_name = p.product_category_name 
JOIN  order_items as oi  on
oi.product_id = p.product_id
group by c.product_category_name_english)


-- Running revenue per category--
running_revenue as (
SELECT c.product_category_name_english, category_revenue, sum(category_revenue) over( order  by category_revenue desc)
as culmulative_revenue
from category_revenue as c 
)

-- PERCENTAGE OF TOTAL REVENUE PER CATEGORY
select r.product_category_name_english,category_revenue,culmulative_revenue,
round((r.culmulative_revenue/sum(r.category_revenue) over())*100,2)
as percentage_total 
from running_revenue as r
order by category_revenue desc;

/*FINDINGS: 17 top categories contributes 80.69% of total revenue. meaning 23% of the categories 
contributes to the 80% of revenue suggesting that more focus should be on these categories to increase revenue.*/

--- TOP SELLERS BY REVENUE----
--  sellers revenue---
 with sellers_revenue as (
select s.seller_id , round(sum(oi.price):: numeric,2 ) as seller_revenue from 
order_items as oi 
 join sellers as s 
on oi.seller_id= s.seller_id 
group by s.seller_id 
order by  seller_revenue desc),

--- culmulative seller_revenue----
culmulative_seller_revenue as(
select s.seller_id ,  s.seller_revenue , sum(s.seller_revenue) over(order by s.seller_revenue desc)
 as  running_seller_revenue from 
sellers_revenue  as s)

-----% of revenue per seller----
select sr.seller_id,sr.seller_revenue, sr.running_seller_revenue ,
round((sr.running_seller_revenue/sum(sr.seller_revenue)over())*100,2) as perc_seller_revenue
from culmulative_seller_revenue as sr
order by seller_revenue desc ;

/* FINDINGS: top 544  of 3095 sellers [17.5%] generate 80.02% of  total revenue  . it is more concentrated 
 than category revenue (top 17 of ~74 categories, ~23%, generate 80%). 
This suggests  that The businesses should prioritize resources, attention, and optimization efforts on these top-performing sellers and categories to maximize 
overall revenue, rather than spreading efforts evenly across all participants. 
but such  low propertion contributing to large amount of revenue the risk is worth monitering.*/

--Order status breakdown — funnel leakage--
-- orders except deliverd and their contribution to total revenue: canceled, invoiced,processed,created,approved
with order_breakdown_count as (
SELECT o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    COALESCE(SUM(p.payment_value), 0) AS total_payment_value
FROM orders AS o
LEFT JOIN payments AS p ON o.order_id = p.order_id
GROUP BY o.order_status
ORDER BY order_count DESC)


SELECT ob.order_status,
		ob.order_count,
		ob.total_payment_value,
		round((ob.order_count::numeric/sum(ob.order_count) over())*100,2) as perc_order_count,
		round((ob.total_payment_value /sum(ob.total_payment_value) over())*100,2) as perc_total_revenue
		from order_breakdown_count as ob
		order by ob.order_count desc

/* FINDING: 2.98% of orders (2,963) never reached "delivered" status, representing 3.66% 
 of total revenue ($586,410) at risk. Treating "shipped" as unresolved (not confirmed delivered) 
 given known gaps in Olist's delivery-date tracking found during validation. 
 "canceled"/"unavailable" alone still show real payment_value attached ($269,735 combined),
 meaning customers were charged for orders that never fulfilled — a real business risk,
 not just an administrative status.*/
