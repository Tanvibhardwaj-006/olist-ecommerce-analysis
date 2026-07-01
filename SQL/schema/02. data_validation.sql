-- COUNTING NUMBER OF ROWS PER TABLE 
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM order_reviews;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM category;

-- CHECKING FOR NULLS
-- Customers
SELECT
    COUNT(*) AS null_customer_ids
FROM customers
WHERE customer_id IS NULL;

-- Orders
SELECT
    COUNT(*) AS null_order_ids
FROM orders
WHERE order_id IS NULL;
--  customer_id check 
SELECT
    COUNT(*) AS null_customer_refs
FROM orders
WHERE customer_id IS NULL;

-- Products
SELECT
    COUNT(*) AS null_product_ids
FROM products
where product_id IS NULL;

-- Sellers
select 
    COUNT(*) AS null_seller_ids
from  sellers
where seller_id IS NULL;

-- Payments
SELECT
    COUNT(*) AS null_payment_values
FROM payments
WHERE payment_value IS NULL;

-------------- ------------------
-- Duplicate customers
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Duplicate orders
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Duplicate products
SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Duplicate sellers
SELECT seller_id, COUNT(*)
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- composite key duplicat
-- ===== UNIQUENESS: composite-key duplicate checks =====
SELECT order_id, order_item_id, COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT order_id, payment_sequential, COUNT(*)
FROM payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

SELECT review_id, order_id, COUNT(*)
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

-- ===== VALIDITY: values within sane ranges =====
SELECT COUNT(*) FROM order_reviews where  review_score NOT BETWEEN 1 AND 5;
SELECT COUNT(*) FROM order_items WHERE price < 0 OR freight_value < 0;
SELECT COUNT(*) FROM payments WHERE payment_value < 0 OR payment_installments <= 0;
SELECT COUNT(*) FROM products where product_weight_g < 0 OR product_length_cm < 0 OR product_height_cm < 0 OR product_width_cm < 0;

-- ===== CONSISTENCY: do dates/statuses logically agree? =====
SELECT COUNT(*) FROM orders WHERE order_delivered_customer_date < order_purchase_timestamp;
SELECT COUNT(*) FROM orders WHERE order_approved_at < order_purchase_timestamp;
SELECT COUNT(*) FROM orders WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;