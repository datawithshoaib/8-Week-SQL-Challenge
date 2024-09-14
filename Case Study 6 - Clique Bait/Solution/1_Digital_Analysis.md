# Clique Bait Case Study

## Digital Analysis

### 1. How many users are there?

```sql
SELECT COUNT(DISTINCT user_id) AS user_count 
FROM users;
```

| user_count   |
|--------------|
| 500          |

---

### 2. How many cookies does each user have on average?

```sql
WITH cookies AS (
	SELECT user_id, COUNT(cookie_id) AS cookie_count
	FROM users
	GROUP BY user_id
)
SELECT AVG(cookie_count) as avg_cookie_count
FROM cookies;
```

| avg_cookie_count |
|----------------- |
| 3.5640           |

---

### 3. What is the unique number of visits by all users per month?

```sql
SELECT 
	MONTH(event_time) AS months,
	COUNT(DISTINCT visit_id) AS visits_count
FROM events
GROUP BY months
ORDER BY months;
```

| months | visits_count |
|--------|--------------|
| 1      | 876          |
| 2      | 1488         |
| 3      | 916          |
| 4      | 248          |
| 5      | 36           |

---

### 4. What is the number of events for each event type?

```sql
SELECT 
	e.event_type, 
    ei.event_name, 
    COUNT(*) AS event_count
FROM events e 
LEFT JOIN event_identifier ei ON e.event_type = ei.event_type
GROUP BY e.event_type, ei.event_name
ORDER BY e.event_type;
```

| event_type | event_name    | event_count |
|------------|---------------|-------------|
| 1          | Page View     | 20928       |
| 2          | Add to Cart   | 8451        |
| 3          | Purchase      | 1777        |
| 4          | Ad Impression | 876         |
| 5          | Ad Click      | 702         |

---

### 5. What is the percentage of visits which have a purchase event?

```sql
SELECT 
	ROUND((COUNT(DISTINCT e.visit_id)/(SELECT COUNT(DISTINCT visit_id) FROM events))*100, 2) AS purchase_pct
FROM events e 
LEFT JOIN event_identifier ei ON e.event_type = ei.event_type
WHERE ei.event_name = 'Purchase';
```

| purchase_pct |
|--------------|
| 49.86        |

---

### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

```sql
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
```

| view_checkout_no_purchase_pct |
|-------------------------------|
| 15.50                         |

---

### 7. What are the top 3 pages by number of views?

```sql
SELECT p.page_name, COUNT(*) AS view_count
FROM events e
LEFT JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 1
GROUP BY p.page_name
ORDER BY view_count DESC
LIMIT 3;
```

| page_name    | view_count |
|--------------|------------|
| All Products | 3174       |
| Checkout     | 2103       |
| Home Page    | 1782       |

---

### 8. What is the number of views and cart adds for each product category?

```sql
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
```

| product_category | page_views | cart_adds |
|------------------|------------|-----------|
| Shellfish        | 6204       | 3792      |
| Fish             | 4633       | 2789      |
| Luxury           | 3032       | 1870      |

---

### 9. What are the top 3 products by purchases?

```sql
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
```

| product_id | product_name | product_category | purchase_count |
|------------|--------------|------------------|----------------|
| 7          | Lobster      | Shellfish        | 754            |
| 9          | Oyster       | Shellfish        | 726            |
| 8          | Crab         | Shellfish        | 719            |

---

Next: [Product Funnel Analysis](2_Product_Funnel_Analysis.md)