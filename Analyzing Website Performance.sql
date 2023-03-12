/*
WEBSITE CONTENT ANAYLSIS
: website content analysis is about understanding which pages are seen the most by your users,
	to identify where to focus on improving your business
COMMON USE CASES
1. Finding the most-viewed pages that customers view on your site
2. Identifying the most common entry pages to your website - the first thing a user sees
3. For most-viewed pages and most common entry pages, 
	understanding how those pages perform for your business objectives    
    
ANALYZING TOP WEBSITE CONTENT / TOP PAGES
where customers are landing on the website and 
how they make their way through the conversion funnel on the path to placing an order
*/

/*
EXAMPLE: CREATING TEMPORARY TABLE
*/

SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE website_pageview_id < 1000 -- arbitrary
GROUP BY 1
ORDER BY 2 DESC;

CREATE TEMPORARY TABLE first_pageview
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE website_pageview_id < 1000 -- arbitrary
GROUP BY website_session_id;

SELECT * FROM first_pageview;

SELECT 
	-- F.website_session_id,
    P.pageview_url AS landing_page, -- aka "entry page"
    COUNT(DISTINCT F.website_session_id) AS session_hitting_this_lander
FROM first_pageview F
	LEFT JOIN website_pageviews P
    ON F.min_pv_id = P.website_pageview_id
GROUP BY 1;

/*
FINDING TOP WEBSITE PAGES (THE MOST VIEWED WEBSITE PAGES)
- Use traffic where the "created_at" was before "2012-06-09"
*/
SELECT *
FROM website_pageviews;

SELECT
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC;

-- "Home" page gets the vast majority of the traffic during this time period, 
-- followed by the "products" and the " original mr fuzzy" page.
-- The remaining pages have a lot less of the volume.

-- NEXT STEPS
-- 1. Dig into whether this list is also representative of our top entry pages
-- 2. Analyze the performance of each of our top pages to look for improvement opportunities

/*
FINDING TOP ENTRY PAGES (LANDING PAGES)
- Pull a list of top entry pages
- Pull all entry pages and rank them on entry volume
*/

-- STEP 1: find the first pageview for each session
-- STEP 2: find the url the customer saw on that first pageview
CREATE TEMPORARY TABLE first_pv_per_session
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_pv
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY 1;

SELECT 
	P.pageview_url AS landing_page,
    COUNT(DISTINCT F.website_session_id) AS sessions_hitting_this_landing_page
FROM first_pv_per_session F
	LEFT JOIN website_pageviews P
    ON F.first_pv = P.website_pageview_id
GROUP BY 1
ORDER BY 2 DESC;

-- Looks like our traffic all comes in through the homepage 
-- Seems pretty obvious where we should focus on making any improvements

-- NEXT STEPS:
-- 1. Analyze landing page performance, for the homepage specifically
-- 2. Think about whether or not the homepage is the best initial experience for all cusotomers

/*
LANDING PAGE PERFORMANCE & OPTIMIZATION TESTING
: landing page analysis and testing is about understanding the performance of your key landing pages 
	and then testing to improve your results
    
COMMON USE CASES:
1. Identifying top opportunities for landing pages
	- high volume pages with higher than expected bounce rates or low conversion rates
2. Setting up A/B experiments on your live traffic to see if you can improve your bounce rates and conversion rates
3. Analyzing test results and making recommendations on which version of landing pages you should use going forward
*/

-- BUSINESS CONTEXT: we want to see landing page performance for a certain time period

-- STEP 1: find the first website_pageview_id for relevant sessions
-- STEP 2: identify the ladning page of each session
-- STEP 3: counting pageviews for each session, to identify "bounces"
-- STEP 4: summarizing total sessions and bounced sessions, by LP

-- finding the minimum website pageview id associated with each session we care about
-- storing the dataset as a temporary tabel
CREATE TEMPORARY TABLE first_pageview_demo
SELECT 
	P.website_session_id,
    MIN(P.website_pageview_id) AS min_pageview_id
FROM website_pageviews P
	INNER JOIN website_sessions S
    ON P.website_session_id = S.website_session_id
    AND S.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- arbitrary
GROUP BY 1;

SELECT *
FROM first_pageview_demo;

-- next, we'll bring in the landing page to each session
CREATE TEMPORARY TABLE sessions_w_landing_page_demo
SELECT 
	F.website_session_id,
    P.pageview_url AS landing_page
FROM first_pageview_demo F
	LEFT JOIN website_pageviews P
    ON F.min_pageview_id = P.website_pageview_id; -- website pageview is the landing page view
    
SELECT *
FROM sessions_w_landing_page_demo;

-- next, we make a table to include a count of pageviews per session

-- first, check on all of the sessions.
-- then, limit to bounced sessions and create a temp table

-- CREATE TEMPORARY TABLE bounced_sessions_only
CREATE TEMPORARY TABLE bounced_sessions_only
SELECT
	L.website_session_id,
    L.landing_page,
    COUNT(DISTINCT P.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_landing_page_demo L
	LEFT JOIN website_pageviews P
    ON L.website_session_id = P.website_session_id
GROUP BY 1, 2
HAVING count_of_pages_viewed = 1;
    
SELECT 
	L.landing_page,
    L.website_session_id,
    B.website_session_id AS bounced_website_session_id
FROM sessions_w_landing_page_demo L
	LEFT JOIN bounced_sessions_only B
	ON L.website_session_id = B.website_session_id
ORDER BY L.website_session_id;

-- final output
-- we will use same query and run a count of records
-- we will group by landing page, and then add a bounce rate column
SELECT 
	L.landing_page,
    COUNT(DISTINCT L.website_session_id) AS sessions,
    COUNT(DISTINCT B.website_session_id) AS bounced_sessions,
	COUNT(DISTINCT B.website_session_id)/COUNT(DISTINCT L.website_session_id) * 100 AS 'bounce_rate(%)'
FROM sessions_w_landing_page_demo L
	LEFT JOIN bounced_sessions_only B
	ON L.website_session_id = B.website_session_id
GROUP BY L.landing_page;

/*
CALCULATING BOUNCE RATES
- All of our traffic is landing on the homepage, so we should check how that landning page is performing.
- Pull bounce rates for traffic landing on the homepage.
- Pull total sessions, total bounced sessions, and bounce rate 
- Use records where the 'created at' Timestamp is less than '2012-06-14'
*/
CREATE TEMPORARY TABLE first_pageviews_id
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews 
WHERE created_at < '2012-06-14'
GROUP BY 1;

-- next, we'll bring in the landing page to each session
-- this is redundant in this case, since all is to the homepage
CREATE TEMPORARY TABLE session_landing_page
SELECT 
	F.website_session_id,
    P.pageview_url AS landing_page
FROM first_pageviews_id F
	LEFT JOIN website_pageviews P
    ON F.min_pageview_id = P.website_pageview_id -- website pageview is the landing page view
WHERE P.pageview_url = '/home';

SELECT * FROM session_landing_page;

-- CREATE TEMPORARY TABLE bounced_session
CREATE TEMPORARY TABLE bounced_session
SELECT
	L.website_session_id,
    L.landing_page,
    COUNT(DISTINCT P.website_pageview_id) AS count_of_pages_viewed
FROM session_landing_page L
	LEFT JOIN website_pageviews P
    ON L.website_session_id = P.website_session_id
GROUP BY 1, 2
HAVING count_of_pages_viewed = 1;

SELECT 
    L.website_session_id,
    B.website_session_id AS bounced_website_session_id
FROM session_landing_page L
	LEFT JOIN bounced_session B
	ON L.website_session_id = B.website_session_id
ORDER BY L.website_session_id;

-- final output
-- we will use same query and run a count of records
-- we will group by landing page, and then add a bounce rate column
SELECT 
	-- L.landing_page,
    COUNT(DISTINCT L.website_session_id) AS sessions,
    COUNT(DISTINCT B.website_session_id) AS bounced_sessions,
	COUNT(DISTINCT B.website_session_id)/COUNT(DISTINCT L.website_session_id) * 100 AS 'bounce_rate(%)'
FROM session_landing_page L
	LEFT JOIN bounced_session B
	ON L.website_session_id = B.website_session_id;
 -- GROUP BY L.landing_page;
 
-- Almost a 60% bounce rate, which is a pretty high bounce rate, especially for paid search
-- NEXT STEPS:
-- 1. Put together a custome landing page for search, and set up an experiment 
-- 		to see if the new page does better.
-- 2. Analyze a new page that maybe improve performance, 
-- 		and analyze the results of an A/B split test against the homepage
 
 /*
Analzing Landing Page
: Based on the bounce rate analysis, we ran a new custom landing page (/lander-1)
	in a 50/50 test against the homepage (/home) for our gsearch nonbrand traffic.
- Pull bounce rates for the two groups to evaluate the new page.
- Make sure to just look at the time period where '/lander' was getting traffic,
	so that it is a fair comparison.
 */
 
-- STEP 1. find out when the new page/lander launched
-- STEP 2. find the first website_pageview_id for relevant sessions
-- STEP 3. identify the landing page of each session
-- STEP 4. count pageviews for each session, to identify "bounces"
-- STEP 5. summarize total sessions and bounced sessions, by LP (landing page)
-- Limit the data to records where 'created at' is less than '2012-07-28'

-- STEP 1
SELECT 
	MIN(created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1'
AND created_at IS NOT NULL;

-- first_created_at = '2012-06-19 00:35:54' -> this is the first time lander-1 was displayed to a customer on the website
-- first pageview_id = 23504
		
-- STEP 2
CREATE TEMPORARY TABLE first_test_pageviews
SELECT 
	 P.website_session_id,
     MIN(P.website_pageview_id) AS min_pageview_id
FROM website_pageviews P
	INNER JOIN website_sessions S
    ON P.website_session_id = S.website_session_id
    AND S.created_at < '2012-07-28' -- prescribed by the assignment
    AND P.website_pageview_id > 23504 -- the min_pageview_id we found 
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1;

SELECT * FROM first_test_pageviews;

-- STEP 3
-- next, we'll bring the landing page to each session, but restricting to home or lander-1

CREATE TEMPORARY TABLE nonbrand_test_session_w_landing_page
SELECT 
	F.website_session_id,
    P.pageview_url AS landing_page
FROM first_test_pageviews F
	LEFT JOIN website_pageviews P
    ON F.min_pageview_id = P.website_pageview_id
WHERE P.pageview_url IN ('/home', '/lander-1');

SELECT * FROM nonbrand_test_session_w_landing_page;

-- STEP 4. count pageviews for each session, to identify "bounces"
-- a table to have count of pageviews per session
-- then limit it to just bounced_sessions
CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT 
	T.website_session_id,
    T.landing_page,
    COUNT(P.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_session_w_landing_page T
	LEFT JOIN website_pageviews P 
    ON T.website_session_id = P.website_session_id
GROUP BY T.website_session_id, T.landing_page
HAVING count_of_pages_viewed = 1;

SELECT * FROM nonbrand_test_bounced_sessions;

-- STEP 5. summarize total sessions and bounced sessions, by LP (landing page)
SELECT 
	T.landing_page,
    T.website_session_id,
    B.website_session_id AS bounced_website_session_id
FROM nonbrand_test_session_w_landing_page T
	LEFT JOIN nonbrand_test_bounced_sessions B
    ON T.website_session_id = B.website_session_id
ORDER BY 
	2;

SELECT 
	T.landing_page,
    COUNT(DISTINCT T.website_session_id) AS sessions,
    COUNT(DISTINCT B.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT B.website_session_id) / COUNT(DISTINCT T.website_session_id) * 100 AS 'bounce_rate(%)'
FROM nonbrand_test_session_w_landing_page T
	LEFT JOIN nonbrand_test_bounced_sessions B
    ON T.website_session_id = B.website_session_id
GROUP BY 1
ORDER BY 4 DESC;

-- New custom lander has a bounce rate of 53% versus the homepage for the same traffic was at 58%
-- Looks like this was an improvement in terms of performance. (it's causing fewer customers to bounce.)

-- NEXT STEPS:
-- 1. Take a look at trends to make sure things have moved in the right direction.
-- 2. Keep an eye on bounce rates and look for other areas to test and optimize.

/*
Ladning Page Trend Analysis
- Pull the volume of paid search nonbrand traffic landing on '/home' and '/lander-1,
	trended weekly since '2012-06-01' to confirm the traffic is all routed correctly.
- Pull the overall paid search bounce rate trended weekly
	to make sure the lander change has imporved the overall picture.
*/

-- STEP 1: finding the first 'website_pageview_id' for relevant sessions
-- STEP 2: identifying the landing page of each session
-- STEP 3: counting pageviews for each sessions, to identify 'bounces'
-- STEP 4: summarizing by week (bounce rate, sessions to each lander)

CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_view_count
SELECT 
	S.website_session_id,
    MIN(P.website_pageview_id) AS first_pageview_id,
    COUNT(P.website_pageview_id) AS count_pageviews
FROM website_sessions S
	LEFT JOIN website_pageviews P
    ON S.website_session_id = P.website_session_id
WHERE S.created_at BETWEEN '2012-06-01' AND '2012-08-31' -- asked by requestor
AND S.utm_source = 'gsearch'
AND S.utm_campaign = 'nonbrand'
GROUP BY 1;

SELECT * FROM sessions_w_min_pv_id_and_view_count;

CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT 
	M.website_session_id,
    M.first_pageview_id,
    M.count_pageviews,
    P.pageview_url AS landing_page,
    P.created_at AS session_created_at
FROM sessions_w_min_pv_id_and_view_count M
	LEFT JOIN website_pageviews P
    ON M.first_pageview_id = P.website_pageview_id;
    
SELECT * FROM sessions_w_counts_lander_and_created_at;

-- final output
SELECT
	-- YEARWEEK(session_created_at) AS year_week,
    MIN(DATE(session_created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)*100 AS 'bounce_rate(%)',
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_w_counts_lander_and_created_at
GROUP BY YEARWEEK(session_created_at);

-- All the traffic has now been routed over to the custom 'lander'
-- Looks like the overall bounce rate has come down over time


/*
ANALYZING & TESTING CONVERSION FUNNELS / CONVERSION FUNNEL ANALYSIS
: is about understanding and optimizing each step of your user experience
	on their journey towards purchasing your products.
- When we build our conversion funnels, we'll be looking at our users, the pages that they land on.
- Then, we'll see what percentage of the users move on to the next step in our flow.
	(i.g. homepage - product page - cart page - billing page - sales)
    
COMMON USE CASES: 
1. Identifying the most common paths customers take before purchasing your products
2. Identifying how many of your users continue on to each next step in your conversion flow,
	and how many users abandon (drop off) at each step
3. Optimizing critical pain points where users are abandoning, 
	so that you can convert more users and sell more products
*/

-- STEP 1: select all pageviews for relevant sessions  
-- STEP 2: identify each relevant pageview as the specific funnel step
-- STEP 3: create the session-level conversion funnel view
-- STEP 4: aggregate the data to assess funnel performance

-- EXAMPLE
SELECT 
	S.website_session_id,
    P.pageview_url,
    P.created_at AS pageview_created_at
	,CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page
    ,CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page
    ,CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
FROM website_sessions S
	LEFT JOIN website_pageviews P
    ON S.website_session_id = P.website_session_id
WHERE S.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- arbitrary 
	AND P.pageview_url IN ('/lander-2', '/products', '/the-original-mr-fuzzy', '/cart')
ORDER BY 
	S.website_session_id,
    P.created_at
;

-- next, we will put the previous query inside a subquery 
-- we will group by website_session_id, and take the MAX() of each of the flags
-- this MAX() becomes a made_it flag for that session, to show the session makde it there

SELECT 
	website_session_id,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it
    -- ,MAX(shipping_page) AS shipping_made_it,
    -- MAX(billing_page) AS billing_made_it,
    -- MAX(thankyou_page) AS thankyou_made_it
FROM(

SELECT 
	S.website_session_id,
    P.pageview_url,
    P.created_at AS pageview_created_at
	,CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page
    ,CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page
    ,CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
FROM website_sessions S
	LEFT JOIN website_pageviews P
    ON S.website_session_id = P.website_session_id
WHERE S.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- arbitrary 
	AND P.pageview_url IN ('/lander-2', '/products', '/the-original-mr-fuzzy', '/cart')
ORDER BY 
	S.website_session_id,
    P.created_at
) AS pageview_level

GROUP BY 1;

-- next, we will turn it into a temp table

CREATE TEMPORARY TABLE session_level_made_it_flags_demo
SELECT 
	website_session_id,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it
    -- ,MAX(shipping_page) AS shipping_made_it,
    -- MAX(billing_page) AS billing_made_it,
    -- MAX(thankyou_page) AS thankyou_made_it
FROM(

SELECT 
	S.website_session_id,
    P.pageview_url,
    P.created_at AS pageview_created_at
	,CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page
    ,CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page
    ,CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
FROM website_sessions S
	LEFT JOIN website_pageviews P
    ON S.website_session_id = P.website_session_id
WHERE S.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- arbitrary 
	AND P.pageview_url IN ('/lander-2', '/products', '/the-original-mr-fuzzy', '/cart')
ORDER BY 
	S.website_session_id,
    P.created_at
) AS pageview_level

GROUP BY 1;

SELECT * FROM session_level_made_it_flags_demo;

-- then, this would produce the final output (part 1)
SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS to_cart
FROM session_level_made_it_flags_demo;

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT website_session_id)*100 AS 'clicked_to_products(%)', -- lander_clickthrough_rate
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN product_made_it  =1 THEN website_session_id ELSE NULL END)*100 AS 'clicked_to_mrfuzzy(%)', -- products_clickthrough_rate
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END)*100 AS 'clicked_to_cart(%)' -- mrfuzzy_clickthrough_rate
FROM session_level_made_it_flags_demo;

/*
Builing Conversion Funnels
- Build a full conversion funnel, analyzing how many customers make it to each step
- Start with '/lander-1' and build the funnel all the way to our 'thankyou page'
- Use data since '2012-08-05' until '2012-09-05'
*/

SELECT DISTINCT(pageview_url) FROM website_pageviews;

SELECT 
	S.website_session_id,
    P.pageview_url,
    P.created_at AS pageview_created_at
	, CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page
    , CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page
    , CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
    , CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
    , CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page
    , CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions S
	LEFT JOIN website_pageviews P
    ON S.website_session_id = P.website_session_id
WHERE 
	S.utm_source = 'gsearch'
	AND S.utm_campaign = 'nonbrand'
	AND S.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND P.pageview_url IN ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
ORDER BY 
	S.website_session_id,
    P.created_at
;

-- create session level conversion funnel view
-- we'll see how far in the conversion funnel each customer went
CREATE TEMPORARY TABLE session_level_made_it
SELECT 
	website_session_id,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM(
	SELECT 
		S.website_session_id,
		P.pageview_url,
		P.created_at AS pageview_created_at
		, CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page
		, CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page
		, CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
		, CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
		, CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page
		, CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM website_sessions S
		LEFT JOIN website_pageviews P
		ON S.website_session_id = P.website_session_id
	WHERE 
		S.utm_source = 'gsearch'
		AND S.utm_campaign = 'nonbrand'
		AND S.created_at BETWEEN '2012-08-05' AND '2012-09-05'
		AND P.pageview_url IN ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
	ORDER BY 
		S.website_session_id,
		P.created_at
    
) AS pageview_level

GROUP BY 1;

SELECT * FROM session_level_made_it;

-- then, this would produce the final output
-- aggregate the data to assess funnel performance
SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it;

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END) 
		/COUNT(DISTINCT website_session_id)*100 AS 'lander_click_rate(%)',
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN product_made_it =1 THEN website_session_id ELSE NULL END)*100 AS 'products_click_rate(%)',
    COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN mrfuzzy_made_it =1 THEN website_session_id ELSE NULL END)*100 AS 'mrfuzzy_click_rate(%)',
	COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN cart_made_it =1 THEN website_session_id ELSE NULL END)*100 AS 'cart_click_rate(%)',
	COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN shipping_made_it =1 THEN website_session_id ELSE NULL END)*100 AS 'shipping_click_rate(%)',
	COUNT(DISTINCT CASE WHEN thankyou_made_it =1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN billing_made_it =1 THEN website_session_id ELSE NULL END)*100 AS 'billing_click_rate(%)'
FROM session_level_made_it;

-- Looks like we should focus on the lander, Mr.fuzzy page, and the billing page, which have the lowest click rates.
-- Test a new billing page which made customers more comfortable entering their credit card info.

-- NEXT STEPS:
-- 1. Analyzing the billing page test 
-- 2. Continue to look for opportunities to improve customer conversion rates

/*
Analyzing Conversion Funnel Tests (A/B spliting test)
- Take a look and see whether '/billing-2' is doing any better than the original '/billing' page
- What percent of sessions on those page end up placing an order
- Ran this test for all traffic, not just for the search visitors
- Limit the data to records before '2012-11-10'
*/

-- STEP 1: finding the first time 'billing-2' was seen
-- STEP 2: final test analysis output

-- finding the first time 'billing-2' was seen
SELECT 
	MIN(created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';

-- first_created_at : 2012-09-10 00:13:05
-- frist_pv_id : 53550


SELECT 
	P.website_session_id
    , P.pageview_url AS billing_version_seen
    , O.order_id
FROM website_pageviews P
	LEFT JOIN orders O
    ON P.website_session_id = O.website_session_id
WHERE P.website_pageview_id >= 53550 -- first pageview_id where test was live
	AND P.created_at < '2012-11-10'
    AND P.pageview_url IN ('/billing', '/billing-2');
    
-- final test analysis output

SELECT 
	billing_version_seen
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT order_id) AS orders
    , COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id)*100 AS 'billing_to_order_rate(%)'
FROM(
	SELECT 
	P.website_session_id
    , P.pageview_url AS billing_version_seen
    , O.order_id
	FROM website_pageviews P
		LEFT JOIN orders O
		ON P.website_session_id = O.website_session_id
	WHERE P.website_pageview_id >= 53550 -- first pageview_id where test was live
		AND P.created_at < '2012-11-10'
		AND P.pageview_url IN ('/billing', '/billing-2')
) AS billing_sessions_w_orders
GROUP BY 1;

-- biling page conversion rate : 46% VS billing2 page conversion rate: 63%
-- Looks like the new version of the billing page is doing much better job converting customers
