## Case Study Questions

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT
	s.customer_id,
	SUM(m.price) AS total_amount
FROM
	sales s
	LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY
	s.customer_id
ORDER BY
	s.customer_id;
```

| customer_id | total_amount |
|-------------|--------------|
| A           | 76           |
| B           | 74           |
| C           | 36           |

---

### 2. How many days has each customer visited the restaurant?

```sql
SELECT
	customer_id,
	COUNT(DISTINCT order_date)
FROM
	sales
GROUP BY
	customer_id
ORDER BY
	customer_id;
```

| customer_id | count |
|-------------|-------|
| A           | 4     |
| B           | 6     |
| C           | 2     |

---

### 3. What was the first item from the menu purchased by each customer?

```sql
SELECT
	customer_id,
	order_date,
	product_name
FROM (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
	FROM
		sales s
		LEFT JOIN menu m ON s.product_id = m.product_id
) AS ranked_sales
WHERE rn = 1
GROUP BY
	customer_id,
	order_date,
	product_name
ORDER BY
	customer_id;
```

| customer_id | order_date  | product_name |
|-------------|-------------|--------------|
| A           | 2021-01-01  | curry        |
| A           | 2021-01-01  | sushi        |
| B           | 2021-01-01  | curry        |
| C           | 2021-01-01  | ramen        |

---

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT
	m.product_name,
	COUNT(*) AS purchase_cnt
FROM
	sales s
	LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY
	m.product_name
ORDER BY
	purchase_cnt DESC
LIMIT 1;
```

| product_name | purchase_cnt |
|--------------|--------------|
| ramen        | 8            |

---

### 5. Which item was the most popular for each customer?

```sql
WITH item_cnts AS (
	SELECT
		s.customer_id,
		m.product_name,
		COUNT(*) AS cnt
	FROM
		sales s
		LEFT JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
	ORDER BY s.customer_id, m.product_name
)

SELECT
	customer_id,
	product_name,
	cnt
FROM (
	SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY cnt DESC) AS rn
	FROM
		item_cnts
) AS ranked_pdts
WHERE rn = 1
ORDER BY
	customer_id,
	product_name;
```

| customer_id | product_name | cnt |
|-------------|--------------|-----|
| A           | ramen        | 3   |
| B           | curry        | 2   |
| B           | ramen        | 2   |
| B           | sushi        | 2   |
| C           | ramen        | 3   |

---

### 6. Which item was purchased first by the customer after they became a member?

```sql
WITH ranked_items AS (
	SELECT 
		s.customer_id,
		me.product_name,
		s.order_date,
		m.join_date,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
	FROM 
		sales s
		LEFT JOIN members m ON s.customer_id = m.customer_id
		LEFT JOIN menu me ON s.product_id = me.product_id
	WHERE 
		m.customer_id IS NOT NULL AND s.order_date >= m.join_date
)
SELECT 
	customer_id,
	product_name,
	order_date,
	join_date
FROM
	ranked_items
WHERE
	rn = 1;
```

| customer_id | product_name | order_date  | join_date  |
|-------------|--------------|-------------|------------|
| A           | curry        | 2021-01-07  | 2021-01-07 |
| B           | sushi        | 2021-01-11  | 2021-01-09 |

---

### 7. Which item was purchased just before the customer became a member?

```sql
WITH ranked_items AS (
	SELECT
		s.customer_id,
		me.product_name,
		s.order_date,
		m.join_date,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
	FROM 
		sales s
		LEFT JOIN members m ON s.customer_id = m.customer_id
		LEFT JOIN menu me ON s.product_id = me.product_id
	WHERE 
		m.customer_id IS NOT NULL AND s.order_date < m.join_date
)
SELECT 
	customer_id,
	product_name,
	order_date,
	join_date
FROM
	ranked_items
WHERE
	rn = 1;
```

| customer_id | product_name | order_date  | join_date  |
|-------------|--------------|-------------|------------|
| A           | sushi        | 2021-01-01  | 2021-01-07 |
| A           | curry        | 2021-01-01  | 2021-01-07 |
| B           | sushi        | 2021-01-04  | 2021-01-09 |

---

### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT
	s.customer_id,
	COUNT(*) AS total_items,
	SUM(me.price) AS amount_spent
FROM
	sales s
	LEFT JOIN members m ON s.customer_id = m.customer_id
	LEFT JOIN menu me ON s.product_id = me.product_id
WHERE 
	m.customer_id IS NOT NULL AND s.order_date < m.join_date
GROUP BY 
	s.customer_id
ORDER BY 
	s.customer_id;
```

| customer_id | total_items | amount_spent |
|-------------|-------------|--------------|
| A           | 2           | 25           |
| B           | 3           | 40           |

---

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier how many points would each customer have?

```sql
SELECT
	s.customer_id,
	SUM(
		CASE 
			WHEN me.product_name = 'sushi' THEN me.price*10*2
			ELSE me.price*10
		END
	) AS points
FROM
	sales s
	LEFT JOIN members m ON s.customer_id = m.customer_id
	LEFT JOIN menu me ON s.product_id = me.product_id
GROUP BY 
	s.customer_id
ORDER BY 
	s.customer_id;
```

| customer_id | points |
|-------------|--------|
| A           | 860    |
| B           | 940    |
| C           | 360    |

---

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
WITH program_validity AS (
	SELECT 
		*,
		DATE(join_date + INTERVAL '6 days') AS valid_date
	FROM members
)

SELECT
	s.customer_id,
	SUM(CASE
		WHEN s.order_date BETWEEN p.join_date AND P.valid_date THEN m.price*10*2
		WHEN m.product_name = 'sushi' THEN m.price*10*2
		ELSE m.price*10
	END) AS total_points
FROM
	sales s
	JOIN program_validity p ON s.customer_id = p.customer_id
	JOIN menu m ON s.product_id = m.product_id
WHERE
	s.order_date <= '2021-01-31'
GROUP BY
	s.customer_id;
```

| customer_id | total_points |
|-------------|--------------|
| A           | 1370         |
| B           | 820          |
