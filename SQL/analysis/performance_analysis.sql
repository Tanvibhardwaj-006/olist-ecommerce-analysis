----------- performace analysis------------
-- revenue per product category--
SELECT c.product_category_name_english, round(sum(o.price):: numeric,2) as category_revenue
FROM category as c JOIN  products as p on 
c.product_category_name = p.product_category_name 
JOIN  order_items as o  on
o.product_id = p.product_id
group by c.product_category_name_english
order by  category_revenue desc;



SELECT c.product_category_name_english, 
FROM category as c JOIN  products as p on 
c.product_category_name = p.product_category_name 
JOIN  order_items as o  on
o.product_id = p.product_id
group by c.product_category_name_english
order by  category_revenue desc;