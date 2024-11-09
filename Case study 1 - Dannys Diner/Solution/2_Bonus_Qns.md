## Bonus Questions

### Join All The Things

```sql
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
```

| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

---

### Rank All The Things

```sql
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
```

| customer_id | order_date  | product_name | price | member | ranking |
|-------------|-------------|--------------|-------|--------|---------|
| A           | 2021-01-01  | curry        | 15    | N      | NULL    |
| A           | 2021-01-01  | sushi        | 10    | N      | NULL    |
| A           | 2021-01-07  | curry        | 15    | Y      | 1       |
| A           | 2021-01-10  | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11  | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11  | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01  | curry        | 15    | N      | NULL    |
| B           | 2021-01-02  | curry        | 15    | N      | NULL    |
| B           | 2021-01-04  | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11  | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16  | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01  | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01  | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01  | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07  | ramen        | 12    | N      | NULL    |


