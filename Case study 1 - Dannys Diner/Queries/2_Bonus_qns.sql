SET search_path = dannys_diner;

-- Join All The Things
SELECT
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	CASE
		WHEN s.order_date < mem.join_date THEN 'N'
		WHEN mem.join_date IS NULL THEN 'N'
		ELSE 'Y'
	END AS member
FROM 
	sales s
	LEFT JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mem ON s.customer_id = mem.customer_id
ORDER BY
	s.customer_id, s.order_date, m.product_name;

-- Rank All The Things
WITH tab AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		CASE
			WHEN s.order_date < mem.join_date THEN 'N'
			WHEN mem.join_date IS NULL THEN 'N'
			ELSE 'Y'
		END AS member
	FROM 
		sales s
		LEFT JOIN menu m ON s.product_id = m.product_id
		LEFT JOIN members mem ON s.customer_id = mem.customer_id
	ORDER BY
		s.customer_id, s.order_date, m.product_name
)

SELECT
	*,
	CASE
		WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
		ELSE null
	END AS ranking
FROM
	tab;
