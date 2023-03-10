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

