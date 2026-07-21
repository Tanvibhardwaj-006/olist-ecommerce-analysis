--- PERFORMANCE ANALYSIS----

--- REVENUE PER CATEGORY ----

 with category_revenue as (
SELECT c.product_category_name_english, round(sum(oi.price):: numeric,2) as category_revenue
FROM category as c JOIN  products as p on 
c.product_category_name = p.product_category_name 
JOIN  order_items as oI  on
oi.product_id = p.product_id
group by c.product_category_name_english
),

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
