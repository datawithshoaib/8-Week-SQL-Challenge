-- set schema to dannys_diner
SET
	SEARCH_PATH = DANNYS_DINER;

-- view tables
SELECT
	*
FROM
	MEMBERS;

SELECT
	*
FROM
	MENU;

SELECT
	*
FROM
	SALES;

-- 1. What is the total amount each customer spent at the restaurant?
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

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
	COUNT(DISTINCT order_date)
FROM
	sales
GROUP BY
	customer_id
ORDER BY
	customer_id;

-- 3. What was the first item from the menu purchased by each customer?
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

-- 4. What is the most purchased item on the menu and 
-- how many times was it purchased by all customers?
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

-- 5. Which item was the most popular for each customer?
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

-- 6. Which item was purchased first by the customer after they became a member?
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

-- 7. Which item was purchased just before the customer became a member?
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

-- 8. What is the total items and amount spent for each member before they became a member?
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

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- - how many points would each customer have?
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

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- - how many points do customer A and B have at the end of January?
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
