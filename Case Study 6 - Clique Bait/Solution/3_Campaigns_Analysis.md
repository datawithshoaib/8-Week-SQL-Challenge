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
```SQL
SELECT * FROM campaign_summary
LIMIT 5;
```

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

```sql
-- Calculate no. of users who received impressions during campaign period
SELECT COUNT(DISTINCT user_id) AS received_impressions
FROM campaign_summary
WHERE impression > 0 
AND campaign_name IS NOT NULL;
```

| received_impressions |
|----------------------|
| 417                  |

```sql
-- Calculate no.of users who received impressions but didn't click on ad
CREATE TEMPORARY TABLE temp_received_clicked AS
	SELECT DISTINCT user_id
    FROM campaign_summary
    WHERE campaign_name IS NOT NULL 
    AND click > 0;

SELECT COUNT(DISTINCT user_id) AS received_impressions_no_click
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
AND user_id NOT IN (
SELECT user_id FROM temp_received_clicked
);
```

| received_impressions_no_click |
|-------------------------------|
| 50                            |

```sql
-- Calculate no.of users who received impressions and clicked on ad
SELECT COUNT(DISTINCT user_id) AS received_impressions_clicked
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
AND user_id IN (
SELECT user_id FROM temp_received_clicked
);
```
| received_impressions_clicked |
|------------------------------|
| 367                          |

```sql
-- Calculate no. of users who didn't receive impressions
CREATE TEMPORARY TABLE temp_users_impressions AS
	SELECT DISTINCT user_id
    FROM campaign_summary
    WHERE campaign_name IS NOT NULL 
    AND impression > 0;

SELECT COUNT(DISTINCT user_id) AS no_impressions
FROM campaign_summary
WHERE campaign_name IS NOT NULL
AND user_id NOT IN (SELECT user_id FROM temp_users_impressions);
```
| no_impressions |
|----------------|
| 78             |


#### Observations:
- No.of users who received impressions during campaign period is 417
- Among these users who received impressions, 50 users didn't click on the ad
- No. of uses who received impressions and clicked on the ad is 367
- No. of users who didn't receive impressions during campaign period is 78

We can calculate impression rate and ad-click rate:

- Impression rate = No.of users who received impressions/Total users in the campaign period = (417/(417 + 78))*100 = 84.24%

- Ad-click rate = No.of users who clicked the ad/No. of users who received impressions = (367/417)*100 = 88.01%

---

- Does clicking on an impression lead to higher purchase rates?

In order to check this, we can calculate the average views, cart adds and purchases

```sql
-- Calculate average views, cart adds, purchases for each group

-- Users who received impressions
SET @received = 417;

SELECT CAST(SUM(page_views)/@received AS DECIMAL(10, 1)) AS avg_page_views,
    CAST(SUM(cart_adds)/@received AS DECIMAL(10,1)) AS avg_cart_adds,
    CAST(SUM(purchase)/@received AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL;
```
| avg_page_views | avg_cart_adds | avg_purchase |
|----------------|---------------|--------------|
| 15.3           | 9.0           | 1.5          |

```sql
-- Users who received impressions and didn't click on ad
SET @received_no_click = 50;

SELECT CAST(SUM(page_views)/@received_no_click AS DECIMAL(10, 1)) AS avg_page_views,
    CAST(SUM(cart_adds)/@received_no_click AS DECIMAL(10,1)) AS avg_cart_adds,
    CAST(SUM(purchase)/@received_no_click AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
AND user_id NOT IN (
SELECT user_id FROM temp_received_clicked
);
```
| avg_page_views | avg_cart_adds | avg_purchase |
|----------------|---------------|--------------|
| 7.6            | 2.7           | 0.8          |

```sql
-- Users who received impressions and clicked on add
SET @received_clicked = 367;

SELECT CAST(SUM(page_views)/@received_clicked AS DECIMAL(10, 1)) AS avg_page_views,
    CAST(SUM(cart_adds)/@received_clicked AS DECIMAL(10,1)) AS avg_cart_adds,
    CAST(SUM(purchase)/@received_clicked AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
AND user_id IN (
SELECT user_id FROM temp_received_clicked
);
```
| avg_page_views | avg_cart_adds | avg_purchase |
|----------------|---------------|--------------|
| 16.4           | 9.9           | 1.6          |

```sql
-- Users who didn't receive impressions
SET @not_received = 78;

SELECT CAST(SUM(page_views)/@not_received AS DECIMAL(10, 1)) AS avg_page_views,
    CAST(SUM(cart_adds)/@not_received AS DECIMAL(10,1)) AS avg_cart_adds,
    CAST(SUM(purchase)/@not_received AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE campaign_name IS NOT NULL
AND user_id NOT IN (SELECT user_id FROM temp_users_impressions);
```
| avg_page_views | avg_cart_adds | avg_purchase |
|----------------|---------------|--------------|
| 19.0           | 5.6           | 1.3          |

#### Insights:
- Average purchase of users who received impressions is 1.5
- Average purchase of users who received impressions but didn't click on ad is 0.8
- Average purchase of users who received impressions and clicked on ad is 1.6
- Average purchase of users who didn't receive impressions is 1.3
- Yes, clicking on impressions (clicking on ad) lead to higher purchase rate: 1.6 > 1.3

---

- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?

Uplift in purchase rate when comparing users who click on a campaign impression vs. users who do not receive an impression = ((1.6 - 1.3)/1.3)*100 = 23.08%

If we compare them with users who just got impression but do not click = ((1.6 - 0.8)/0.8)*100 = 100%

- Clicking on the ad leads to a 23.08% higher purchase rate compared to those who did not receive an impression.
- Clicking on the ad leads to a 100% higher purchase rate compared to those who received an impression but didn't click.
---

- What metrics can you use to quantify the success or failure of each campaign compared to eachother?

We can find the average views, cart adds and purchases for each campaign and compare which campaign has performed well.

```sql
-- average views, cart adds and purchases for each campaign
-- for users who received impressions
SELECT campaign_name, 
	CAST(SUM(page_views)/@received AS DECIMAL(10, 1)) AS avg_page_views,
    CAST(SUM(cart_adds)/@received AS DECIMAL(10,1)) AS avg_cart_adds,
    CAST(SUM(purchase)/@received AS DECIMAL(10,1)) AS avg_purchase
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
GROUP BY campaign_name;
```
| campaign_name                     | avg_page_views | avg_cart_adds | avg_purchase |
|------------------------------------|----------------|---------------|--------------|
| Half Off - Treat Your Shellf(ish)  | 11.8           | 6.9           | 1.2          |
| 25% Off - Living The Lux Life      | 2.2            | 1.3           | 0.2          |
| BOGOF - Fishing For Compliments    | 1.4            | 0.8           | 0.1          |

- The "Half Off - Treat Your Shellf(ish)" campaign performed the best across all metrics - highest page views, cart adds, and purchases - indicating that it was the most successful in driving both interest and conversions.


We can find the Conversion Rate for each campaign (conversion rate is the ratio of no.of purchases to the no.of impressions)

```sql
-- Conversion Rate for each campaign
-- ratio of no.of purchases to the no.of impressions
SELECT campaign_name,
	SUM(purchase) AS purchases, 
    SUM(impression) AS impressions,
	CAST(SUM(purchase)/SUM(impression) AS DECIMAL(10, 2)) AS conversion_rate
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
GROUP BY campaign_name;
```
| campaign_name                     | purchases | impressions | conversion_rate |
|------------------------------------|-----------|-------------|-----------------|
| Half Off - Treat Your Shellf(ish)  | 493       | 578         | 0.85            |
| 25% Off - Living The Lux Life      | 87        | 104         | 0.84            |
| BOGOF - Fishing For Compliments    | 55        | 65          | 0.85            |


#### Insights & Recommendations:

- "Half Off - Treat Your Shellf(ish)" is the standout campaign in terms of total sales and reach, despite having a conversion rate similar to the other two campaigns.

- The high conversion rates across all campaigns suggest that users who engage are highly likely to purchase, but the total impressions (reach) play a major role in determining overall success.

- To improve the impact of campaigns like "Living The Lux Life" and "Fishing For Compliments", focusing on increasing impressions (i.e., expanding the audience) could lead to higher total purchases.


We can find the Click Through Rate which measures how often users click on the ad after seeing it. A higher CTR indicates a more engaging ad.

```sql
-- Click Through Rate for each campaign
-- ratio of no.of clicks to the no.of impressions
SELECT campaign_name,
	SUM(click) AS clicks, 
    SUM(impression) AS impressions,
	CAST(SUM(click)/SUM(impression) AS DECIMAL(10, 2)) AS click_through_rate
FROM campaign_summary
WHERE impression > 0
AND campaign_name IS NOT NULL
GROUP BY campaign_name;
```
| campaign_name                     | clicks | impressions | click_through_rate |
|------------------------------------|--------|-------------|--------------------|
| Half Off - Treat Your Shellf(ish)  | 463    | 578         | 0.80               |
| 25% Off - Living The Lux Life      | 81     | 104         | 0.78               |
| BOGOF - Fishing For Compliments    | 55     | 65          | 0.85               |

#### Insights & Recommendations:

- "BOGOF - Fishing For Compliments" is the most engaging campaign in terms of CTR, but due to the limited reach (fewer impressions), it generated fewer total clicks.

- "Half Off - Treat Your Shellf(ish)" strikes a good balance between high CTR and larger reach, making it the overall winner in terms of driving clicks and engagement.

- All campaigns have strong click-through rates, but increasing impressions for the campaigns with fewer clicks could improve their overall performance.