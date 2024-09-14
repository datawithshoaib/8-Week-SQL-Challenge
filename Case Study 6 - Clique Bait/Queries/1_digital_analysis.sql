-- --------- Digital Analysis ----------------------

-- How many users are there?
SELECT COUNT(DISTINCT user_id) AS user_count 
FROM users;

-- How many cookies does each user have on average?
WITH cookies AS (
	SELECT user_id, COUNT(cookie_id) AS cookie_count
	FROM users
	GROUP BY user_id
)
SELECT AVG(cookie_count) as avg_cookie_count
FROM cookies;

-- What is the unique number of visits by all users per month?
SELECT 
	MONTH(event_time) AS months,
	COUNT(DISTINCT visit_id) AS visits_count
FROM events
GROUP BY months
ORDER BY months;

-- What is the number of events for each event type?
SELECT 
	e.event_type, 
    ei.event_name, 
    COUNT(*) AS event_count
FROM events e 
LEFT JOIN event_identifier ei ON e.event_type = ei.event_type
GROUP BY e.event_type, ei.event_name
ORDER BY e.event_type;

-- What is the percentage of visits which have a purchase event?

SELECT 
	ROUND((COUNT(DISTINCT e.visit_id)/(SELECT COUNT(DISTINCT visit_id) FROM events))*100, 2) AS purchase_pct
FROM events e 
LEFT JOIN event_identifier ei ON e.event_type = ei.event_type
WHERE ei.event_name = 'Purchase';

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
-- count of visits which has checkout page but not purchase event/count of visits which has checkout page
SELECT
	ROUND(
		((SELECT COUNT(DISTINCT visit_id)
		FROM events
		WHERE page_id = 12 and visit_id NOT IN (SELECT DISTINCT visit_id FROM events WHERE event_type = 3))/ 
		(SELECT COUNT(DISTINCT visit_id) 
        FROM events 
        WHERE page_id = 12))
	*100, 2)
AS view_checkout_no_purchase_pct;

-- What are the top 3 pages by number of views?
SELECT p.page_name, COUNT(*) AS view_count
FROM events e
LEFT JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 1
GROUP BY p.page_name
ORDER BY view_count DESC
LIMIT 3;

-- What is the number of views and cart adds for each product category?
SELECT
	p.product_category,
    SUM(CASE WHEN ei.event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category
ORDER BY page_views DESC;

-- What are the top 3 products by purchases?
SELECT p.product_id, 
	   p.page_name AS product_name, 
       p.product_category, 
	   COUNT(*) AS purchase_count
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE ei.event_name = 'Add to Cart'
AND e.visit_id IN (
	SELECT e.visit_id
    FROM events e
    JOIN event_identifier ei ON e.event_type = ei.event_type
    WHERE ei.event_name = 'Purchase')
GROUP BY p.product_id, product_name, p.product_category
ORDER BY purchase_count DESC
LIMIT 3;
