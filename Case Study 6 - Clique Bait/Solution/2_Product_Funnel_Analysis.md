# Clique Bait Case Study

## Product Funnel Analysis

Using a single SQL query - create a new output table which has the following details:

- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?

### SQL Query:
```sql
CREATE TEMPORARY TABLE product_summary AS
-- How many times was each product viewed?
WITH product_views AS (
SELECT p.product_id, p.page_name, COUNT(*) AS page_views
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 1 AND p.product_id IS NOT NULL
GROUP BY p.page_name, p.product_id
),

-- How many times was each product added to cart?
cart_adds AS (
SELECT p.page_name, COUNT(*) AS add_cart_count
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
WHERE e.event_type = 2 AND p.product_id IS NOT NULL
GROUP BY p.page_name
),

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

-- check the created table
SELECT * FROM product_summary;
```

| product_id | page_name       | page_views | add_cart_count | added_cart_no_purchase_count | purchase_count |
|------------|-----------------|------------|----------------|------------------------------|----------------|
| 1          | Salmon          | 1559       | 938            | 227                          | 711            |
| 2          | Kingfish        | 1559       | 920            | 213                          | 707            |
| 3          | Tuna            | 1515       | 931            | 234                          | 697            |
| 4          | Russian Caviar  | 1563       | 946            | 249                          | 697            |
| 5          | Black Truffle   | 1469       | 924            | 217                          | 707            |
| 6          | Abalone         | 1525       | 932            | 233                          | 699            |
| 7          | Lobster         | 1547       | 968            | 214                          | 754            |
| 8          | Crab            | 1564       | 949            | 230                          | 719            |
| 9          | Oyster          | 1568       | 943            | 217                          | 726            |

---

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

```sql
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
AND e.visit_id IN ( 
	SELECT e.visit_id 
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

-- check the category summary
SELECT * FROM category_summary;
```

| product_category | page_views | add_cart_count | added_cart_no_purchase_count | purchase_count |
|------------------|------------|----------------|------------------------------|----------------|
| Fish             | 4633       | 2789           | 674                          | 2115           |
| Luxury           | 3032       | 1870           | 466                          | 1404           |
| Shellfish        | 6204       | 3792           | 894                          | 2898           |

---

Use your 2 new output tables - answer the following questions:

#### 1. Which product had the most views, cart adds and purchases?

```sql
-- product with most views
SELECT *
FROM product_summary
ORDER BY page_views DESC
LIMIT 1;
```
| product_id | page_name | page_views | add_cart_count | added_cart_no_purchase_count | purchase_count |
|------------|-----------|------------|----------------|------------------------------|----------------|
| 9          | Oyster    | 1568       | 943            | 217                          | 726            |


```sql
-- product with most cart adds
SELECT *
FROM product_summary
ORDER BY add_cart_count DESC
LIMIT 1;
```
| product_id | page_name | page_views | add_cart_count | added_cart_no_purchase_count | purchase_count |
|------------|-----------|------------|----------------|------------------------------|----------------|
| 7          | Lobster   | 1547       | 968            | 214                          | 754            |


```sql
-- product with most purchases
SELECT *
FROM product_summary
ORDER BY purchase_count DESC
LIMIT 1;
```
| product_id | page_name | page_views | add_cart_count | added_cart_no_purchase_count | purchase_count |
|------------|-----------|------------|----------------|------------------------------|----------------|
| 7          | Lobster   | 1547       | 968            | 214                          | 754            |

---

#### 2. Which product was most likely to be abandoned?

```sql
SELECT *
FROM product_summary
ORDER BY added_cart_no_purchase_count DESC
LIMIT 1;
```
| product_id | page_name        | page_views | add_cart_count | added_cart_no_purchase_count | purchase_count |
|------------|------------------|------------|----------------|------------------------------|----------------|
| 4          | Russian Caviar   | 1563       | 946            | 249                          | 697            |

---

#### 3. Which product had the highest view to purchase percentage?

```sql
SELECT product_id, page_name, ROUND((purchase_count/page_views)*100, 2) AS purchase_view_pct
FROM product_summary
ORDER BY purchase_view_pct DESC
LIMIT 1;
```
| product_id | page_name | purchase_view_pct |
|------------|-----------|-------------------|
| 7          | Lobster   | 48.74             |

---

#### 4. What is the average conversion rate from view to cart add?
```sql
SELECT ROUND(AVG(add_cart_count/page_views)*100, 2) AS avg_view_cart_conv_rate
FROM product_summary
ORDER BY avg_view_cart_conv_rate DESC
LIMIT 1;
```
| avg_view_cart_conv_rate |
|-------------------------|
| 60.95                   |

---

#### 5. What is the average conversion rate from cart add to purchase?
```sql
SELECT ROUND(AVG(purchase_count/add_cart_count)*100, 2) AS avg_cart_purchase_conv_rate
FROM product_summary
ORDER BY avg_cart_purchase_conv_rate DESC
LIMIT 1;
```
| avg_cart_purchase_conv_rate |
|-----------------------------|
| 75.93                       |

---

Next: [Campaign Analysis](3_Campaigns_Analysis.md)
