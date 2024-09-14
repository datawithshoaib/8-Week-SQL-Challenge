-- Campaign summary
CREATE TEMPORARY TABLE campaign_summary AS
SELECT
    u.user_id,
    e.visit_id,
    MIN(event_time) AS visit_start_time,
    SUM(CASE WHEN ei.event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
    SUM(CASE WHEN ei.event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
    c.campaign_name,
    SUM(CASE WHEN ei.event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
    SUM(CASE WHEN ei.event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
    GROUP_CONCAT(CASE WHEN ei.event_name = 'Add to Cart' THEN ph.page_name END 
				 ORDER BY e.sequence_number SEPARATOR ', ') AS cart_products
FROM events e
JOIN users u ON e.cookie_id = u.cookie_id
JOIN event_identifier ei ON e.event_type = ei.event_type
JOIN page_hierarchy ph ON e.page_id = ph.page_id
LEFT JOIN campaign_identifier c ON e.event_time BETWEEN c.start_date AND c.end_date
GROUP BY u.user_id, e.visit_id, c.campaign_name;

SELECT COUNT(*) FROM campaign_summary;

select * from campaign_summary
LIMIT 5;

-- Calculate no. of users who received impressions during campaign period
SELECT COUNT(DISTINCT user_id) AS received_impressions
FROM campaign_summary
WHERE impression > 0 
AND campaign_name IS NOT NULL;

-- Calculate no.of users who received impressions but didn't click on ad
SELECT COUNT(DISTINCT user_id) AS received_impressions_no_click
FROM campaign_summary
WHERE impression > 0
AND click = 0
AND campaign_name IS NOT NULL;

-- Calculate no. of users who didn't receive impressions
CREATE TEMPORARY TABLE temp_users_no_impressions AS
	SELECT DISTINCT user_id
    FROM campaign_summary
    WHERE impression > 0;

SELECT COUNT(DISTINCT user_id) AS no_impressions
FROM campaign_summary
WHERE campaign_name IS NOT NULL
AND user_id NOT IN (SELECT user_id FROM temp_users_no_impressions);

-- Calculate average views, cart adds, purchase for each group
-- Users who received impressions
SET @received = 417;

SELECT CAST(SUM(page_views)/@received AS DECIMAL(10, 1)) AS avg_page_views,
	   CAST(SUM(cart_adds)/@received AS DECIMAL(10,1)) AS avg_cart_adds,
       CAST(SUM(purchase)/@received AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL;

-- Users who received impressions and didn't click on add
SET @received_no_click = 127;

SELECT CAST(SUM(page_views)/@received_no_click AS DECIMAL(10, 1)) AS avg_page_views,
	   CAST(SUM(cart_adds)/@received_no_click AS DECIMAL(10,1)) AS avg_cart_adds,
       CAST(SUM(purchase)/@received_no_click AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE impression > 0
AND click = 0
AND campaign_name IS NOT NULL;

-- Users who didn't receive impressions
SET @not_received = 56;

SELECT CAST(SUM(page_views)/@not_received AS DECIMAL(10, 1)) AS avg_page_views,
	   CAST(SUM(cart_adds)/@not_received AS DECIMAL(10,1)) AS avg_cart_adds,
       CAST(SUM(purchase)/@not_received AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE campaign_name IS NOT NULL
AND user_id NOT IN (SELECT user_id FROM temp_users_no_impressions);
