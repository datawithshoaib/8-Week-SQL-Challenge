-- Using a single SQL query

CREATE TABLE product_summary AS
-- How many times was each product viewed?
WITH product_views AS (
SELECT p.product_id, p.page_name, COUNT(*) AS page_views
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 1 AND p.product_id IS NOT NULL
GROUP BY p.page_name, p.product_id
),
-- select * from product_views;

-- How many times was each product added to cart?
cart_adds AS (
SELECT p.page_name, COUNT(*) AS add_cart_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 2 AND p.product_id IS NOT NULL
GROUP BY p.page_name
),
-- select * from add_cart;

-- How many times was each product added to a cart but not purchased (abandoned)?
added_cart_not_purchased AS (
SELECT p.page_name, 
	   COUNT(*) AS added_cart_no_purchase_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 2 AND e.visit_id NOT IN (
										SELECT e.visit_id 
										FROM events e
										WHERE e.event_type = 3)
GROUP BY p.page_name
),

-- How many times was each product purchased?
purchases AS (
SELECT p.page_name, COUNT(*) AS purchase_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
JOIN event_identifier ei ON e.event_type = ei.event_type
WHERE ei.event_name = 'Add to Cart'
AND e.visit_id IN ( SELECT e.visit_id 
					FROM events e
                    JOIN event_identifier ei ON e.event_type = ei.event_type
 					WHERE ei.event_name = 'Purchase' )
GROUP BY p.page_name
)

SELECT pv.*,
	   ca.add_cart_count,
       anp.added_cart_no_purchase_count,
       p.purchase_count
FROM product_views pv
JOIN cart_adds ca ON pv.page_name = ca.page_name
JOIN added_cart_not_purchased anp ON pv.page_name = anp.page_name
JOIN purchases p ON pv.page_name = p.page_name
ORDER BY pv.product_id;

SELECT * FROM product_summary;

-- Additionally, create another table which further aggregates the data for the above points 
-- but this time for each product category instead of individual products

-- How many times was each product viewed?
WITH product_views AS (
SELECT p.product_category, COUNT(*) AS page_views
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 1 AND p.product_id IS NOT NULL
GROUP BY p.product_category
),

-- How many times was each product added to cart?
cart_adds AS (
SELECT p.product_category, COUNT(*) AS add_cart_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 2 AND p.product_id IS NOT NULL
GROUP BY p.product_category
),

-- How many times was each product added to a cart but not purchased (abandoned)?
added_cart_not_purchased AS (
SELECT p.product_category, 
	   COUNT(*) AS added_cart_no_purchase_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 2 AND e.visit_id NOT IN (
										SELECT e.visit_id 
										FROM events e
										WHERE e.event_type = 3)
GROUP BY p.product_category
),

-- How many times was each product purchased?
purchases AS (
SELECT p.product_category, COUNT(*) AS purchase_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
JOIN event_identifier ei ON e.event_type = ei.event_type
WHERE ei.event_name = 'Add to Cart'
AND e.visit_id IN ( SELECT e.visit_id 
					FROM events e
                    JOIN event_identifier ei ON e.event_type = ei.event_type
 					WHERE ei.event_name = 'Purchase' )
GROUP BY p.product_category
),

category_summary AS (
SELECT pv.*,
	   ca.add_cart_count,
       anp.added_cart_no_purchase_count,
       p.purchase_count
FROM product_views pv
JOIN cart_adds ca ON pv.product_category = ca.product_category
JOIN added_cart_not_purchased anp ON pv.product_category = anp.product_category
JOIN purchases p ON pv.product_category = p.product_category
ORDER BY pv.product_category
)

SELECT * FROM category_summary;

-- Use your 2 new output tables - answer the following questions

-- 1. Which product had the most views, cart adds and purchases?
-- product with most views
SELECT *
FROM product_summary
ORDER BY page_views DESC
LIMIT 1;

-- product with most cart adds
SELECT *
FROM product_summary
ORDER BY add_cart_count DESC
LIMIT 1;

-- product with most purchases
SELECT *
FROM product_summary
ORDER BY purchase_count DESC
LIMIT 1;


-- 2. Which product was most likely to be abandoned?
SELECT *
FROM product_summary
ORDER BY added_cart_no_purchase_count DESC
LIMIT 1;

-- 3. Which product had the highest view to purchase percentage?
SELECT product_id, page_name, ROUND((purchase_count/page_views)*100, 2) AS purchase_view_pct
FROM product_summary
ORDER BY purchase_view_pct DESC
LIMIT 1;

-- 4. What is the average conversion rate from view to cart add?
SELECT ROUND(AVG(add_cart_count/page_views)*100, 2) AS avg_view_cart_conv_rate
FROM product_summary
ORDER BY avg_view_cart_conv_rate DESC
LIMIT 1;

-- 5. What is the average conversion rate from cart add to purchase?
SELECT ROUND(AVG(purchase_count/add_cart_count)*100, 2) AS avg_cart_purchase_conv_rate
FROM product_summary
ORDER BY avg_cart_purchase_conv_rate DESC
LIMIT 1;

-- see product summary table
SELECT * FROM product_summary;
