/* We will be working with six related tables, whivh contain eCommnerce data about:
1. Website Activity
2. Products
3. Orders and Refunds

We will use MySQL to understand how customers access and interact with the site, 
analyze landing page performance and conversion, and explore product-level sales.
*/

/* Traffic Source Analysis / Conversion Analysis / Funnel Analysis
: Traffic source analysis is about understanding where your customers are coming from and 
	which channels are driving the highest quality traffic. (e.g. email, social, search, direct..)

- COMMON USE CASES:
1. Analyzing search data and shifting budet towards one engine to another, 
	campaigns or keywords driving the strongest conversion rates
2. Comparing user behavior patterns across traffic sources to infrom creative and messaging strategy
3. Identifying opportunities to eliminate wasted spend or scale high-converting traffic
*/
SELECT * FROM website_sessions
WHERE website_session_id = 1059;

SELECT * FROM website_pageviews
WHERE website_session_id = 1059;

SELECT * FROM orders
WHERE website_session_id = 1059;

/*
Traffic Source Analysis
1. We use the utm parameters stored in the database to identify paid website sessions.
2. From our session data, we can link to our order data 
	to understand how much revenue our paid campaings are driving. 
*/
-- USE mavenfuzzyfactory;
SELECT 
	website_sessions.utm_content,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt
FROM website_sessions
	LEFT JOIN orders 
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.website_session_id BETWEEN 1000 AND 2000 -- arbitrary
GROUP BY 1
ORDER BY 2 DESC;
    
/*
Finding Top Traffic Sources
: to understand where the bulk of the website sessions are coming from
: breakdown by UTM source, campaign and referring domain
*/
SELECT 
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions -- session volume
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 1,2,3
ORDER BY 4 DESC;

-- Seems like "gsearch nonbrand" is the major traffic source
-- NEXT STEPS!!!
-- : Drill deeper into 'gsearhc nonbrand' campaign traffic to explore potential optimization opportunities

/*
Traffic Source Conversion Rates (from sessions to orders)
: to figure out if those sessions are driving sales
: calculate the Conversion rate(CVR) from sessions to order 
  (= What percentage of sessions convert to a sale for the company)
*/
SELECT 
	COUNT(DISTINCT S.website_session_id) AS sessions,
    COUNT(DISTINCT O.order_id) AS orders,
    COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id) * 100 AS session_to_order_conv_rate
FROM website_sessions S
	LEFT JOIN orders O
    ON S.website_session_id = O.website_session_id
WHERE S.created_at < '2012-04-14'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';

-- Looks like we're below the 4% threshold we need to make the economics work (2.86%). 
-- Based on the current CVR, we'll need to dial down our search bids a bit because we are over-spending.
-- NEXT STEPS:
-- 1. Monitor the impact of bid reductions
-- 2. Analyze performance trending by device type in order to refine bidding strategy

/*
BID OPTIMIZATION & TREND ANALYSIS
: Analyzing for bid optimization is about understanding the value of various segments of paid traffic, 
so that you can optimize your marketing budget.

- COMMON USE CASES
1. Using conversion rate and revenue per click analyses to figure out how much you should spend per click 
	to acquire customers
2. Understanding how your website and products perform for various subsegments of traffic 
	(i.e. mobile vs desktop) to optimize within channels
3. Analyzing the impact that bid changes have on your ranking in the paid auctions, 
	and the volume of customers driven to your site (the paid marketing channels)
*/

-- Example 1 (for trend analysis)
SELECT
	YEAR(created_at),
    WEEK(created_at),
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary
GROUP BY 1,2;

-- Example 2 (pivoting data with COUNT & CASE)
SELECT 
	primary_product_id,
    COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS orders_w_1_items,
    COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS orders_w_2_items,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000 -- arbitraty
GROUP BY 1;

/*
Traffic Source Trending
- Based on the CVR analysis, we bid down gsearch nonbrand on 2012-04-15.
- Pull gsearch nonbrand trended session volume, by week 
	to see if the bid changes have caused volume to drop at all.
- Limit your query to sessions where the 'created_at' is less than May 10th,2012.
*/
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at);
    

-- Based on this results, it does look like gsearch nonbrand is fairy sensitive to bid changes.
-- But, we want maximaize volume and don't want to spend more on ads than we can afford.

-- NEXT STEPS:
-- 1. Continue to monitor volumes levels
-- 2. Think about how we could make the campaigns more efficient so that we can increase volume agian.

/*
Pull conversion rates from session to order, split by device type
- so that we can more appropriately set bids at the device type level.
- if desktop performance is better than on mobile 
	we may be able to bid up for desktop specifically to get more volume. 

- Use data where 'created at' is less than '2012-05-11'
*/
SELECT 
	S.device_type,
    COUNT(DISTINCT S.website_session_id) AS sessions,
    COUNT(DISTINCT O.order_id) AS orders,
    ROUND(COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id)*100, 2) AS 'session_to_order_conv_rate(%)'
FROM website_sessions S
	LEFT JOIN orders O 
    ON S.website_session_id = O.website_session_id
WHERE S.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1;

-- CVR for desktop traffic is about 3.73%, which matriculates to a revenue generating order for the business
-- For mobile traffic, it's less than 1%.
-- Desktop performs way better than mobile.
-- Based on this results, we are going to increase our bids on desktop.

-- NEXT STEPS
-- 1. Analyze volume by device type to see if the bid changes make a material impact
-- 2. Continue to look for ways to optimize campaigns

/*
Traffic Source Segment Trending / Granular Segments
: After the device-level analysis of conversion rate, we bid our gsearch nonbrand desktop campaigns up 
	on '2012-05-19'
- Pull weekly trends for both desktop and mobile so we can see the impact on volume
- Use '2012-04-15' until the bid change as a baseline
*/
SELECT 
	MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at);
    
-- NEXT STEPS:
-- 1. Continue to monitor device-level volume and be aware of the impact bid levels has
-- 2. Continue to monitor conversion performance at the device-level to optimize spend
/*
This analysis help a channel marketing manager, 
figuring out where the oppoortunities are,
how you can optimize your bids, 
confirming whether or not that bid optimization had the intended effect that they were hoping
*/
	
