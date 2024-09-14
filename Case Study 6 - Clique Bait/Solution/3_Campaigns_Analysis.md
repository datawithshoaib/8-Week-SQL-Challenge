# Clique Bait Case Study

## Campaigns Analysis

Generate a table that has 1 single row for every unique visit_id record and has the following columns:

- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

### SQL Query:
```sql
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
```

First 5 rows:
| user_id | visit_id | visit_start_time     | page_views | cart_adds | purchase | campaign_name                     | impression | click | cart_products                                          |
|---------|----------|----------------------|------------|-----------|----------|----------------------------------|------------|-------|--------------------------------------------------------|
| 1       | 02a5d5  | 2020-02-26 16:57:26  | 4          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | NULL                                                   |
| 1       | 0826dc  | 2020-02-26 05:58:38  | 1          | 0         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | NULL                                                   |
| 1       | 0fc437  | 2020-02-04 17:49:50  | 10         | 6         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster |
| 1       | 30b94d  | 2020-03-15 13:12:54  | 9          | 7         | 1        | Half Off - Treat Your Shellf(ish) | 1          | 1     | Salmon, Kingfish, Tuna, Russian Caviar, Abalone, Lobster, Crab |
| 1       | 41355d  | 2020-03-25 00:11:18  | 6          | 1         | 0        | Half Off - Treat Your Shellf(ish) | 0          | 0     | Lobster                                               |


---

Some ideas you might want to investigate further include:

- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
- Does clicking on an impression lead to higher purchase rates?
- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
- What metrics can you use to quantify the success or failure of each campaign compared to eachother?

