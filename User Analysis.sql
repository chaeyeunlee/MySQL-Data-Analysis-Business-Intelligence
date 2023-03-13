/*
BUSINESS CONCEPT: ANALYZE REPEAT (VISIT & PURCHASE) BEHAVIOR
: Analyzing repeat visits helps you understand user behavior and identify some of your most valuable customers

COMMON USE CASES:
1. Analyzing repeat activity to see how often customers are coming back to visit your site
2. Understanding which channels they use when they come back, 
	and whether or not you are paying for them again through paid channels
3. Using your repeat visit activity to build a better understanding of the value of a customer
	 in order to better optimize marketing channels (budgets)
     
TRACKING REPEAT CUSTOMER ACROSS MULTIPLE SESSIONS
: Businesses track customer behavior across multiple sessions using "browser cookies"
- Cookies have unique ID values associated with them, which allows us to recognize a customer
	when they come back and track their behavior over time

*/
SELECT * FROM website_sessions;


/*
Identifying Repeat Visitors
- Pull data on how many of our website visitors come back for another session.
- Use time period from '2014-01-01' before '2014-11-01'
*/

CREATE TEMPORARY TABLE sessions_w_repeats
SELECT 
	N.user_id
    , N.website_session_id AS new_session_id
    , S.website_session_id AS repeat_session_id
FROM(
SELECT 
	user_id
    , website_session_id
FROM website_sessions
WHERE created_at < '2014-11-01' -- the date of the assignment
	AND created_at >= '2014-01-01' -- prescribed date range in assignment
    AND is_repeat_session = 0 -- new sessions only
) AS N

LEFT JOIN website_sessions S
	ON N.user_id = S.user_id
    AND S.is_repeat_session = 1 -- was a repeat session 
    AND S.website_session_id > N.website_session_id -- session was later than new session
    AND S.created_at < '2014-11-01'
    AND S.created_at >= '2014-01-01'
;

SELECT * FROM sessions_w_repeats;

SELECT 
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM(
SELECT
	user_id
    , COUNT(DISTINCT new_session_id) AS new_sessions
    , COUNT(DISTINCT repeat_session_id) AS repeat_sessions
FROM sessions_w_repeats
GROUP BY 1
ORDER BY 3 DESC
) AS user_level

GROUP BY 1;

-- A fair number of our customers do come back to our site after the first session

/*
Analyzing Time to Repeat
- Pull the minimum, maximum, and average time between the first and second session for customers who do come back
- Analyze 2014 to date ('2014-11-03')
*/

-- STEP 1: Identify the relevant new sessions
-- STEP 2: User the user_id values from STEP 1 to find any repeat sessions those users had
-- STEP 3: Find the created_at times for first and second sessions
-- STEP 4: Find the differences between first and second sessions at a user level
-- STEP 5: Aggregate the user level data to find the average, min, max

-- STEP 1: Identify the relevant new sessions
-- STEP 2: User the user_id values from STEP 1 to find any repeat sessions those users had
CREATE TEMPORARY TABLE sessions_w_repeats_for_time_diff
SELECT
	N.user_id
    , N.website_session_id AS new_session_id
    , N.created_at AS new_session_created_at
    , S.website_session_id AS repeat_session_id
    , S.created_at As repeat_session_created_at

FROM
(
SELECT 
	user_id
    , website_session_id
    , created_at
FROM website_sessions
WHERE 
	created_at < '2014-11-03' -- the date of assignment
	AND created_at >= '2014-01-01'
    AND is_repeat_session = 0 -- new sessions only
) AS N
	LEFT JOIN website_sessions S
		ON N.user_id = S.user_id
        AND S.is_repeat_session = 1 -- repeat sessions only
        AND S.website_session_id > N.website_session_id
        AND S.created_at < '2014-11-03'
        AND S.created_at >= '2014-01-01'
;
		
SELECT * FROM sessions_w_repeats_for_time_diff;

-- STEP 3: Find the created_at times for first and second sessions
-- STEP 4: Find the differences between first and second sessions at a user level
CREATE TEMPORARY TABLE user_first_to_second
SELECT
	user_id
    , DATEDIFF(second_session_created_at, new_session_created_at) AS days_first_to_second_session
FROM
(
SELECT 
	user_id
    , new_session_id
    , new_session_created_at
    , MIN(repeat_session_id) AS second_session_id
    , MIN(repeat_session_created_at) AS second_session_created_at
FROM sessions_w_repeats_for_time_diff
WHERE repeat_session_id IS NOT NULL
GROUP BY 1,2,3
) AS first_second;

SELECT * FROM user_first_to_second;


-- STEP 5: Aggregate the user level data to find the average, min, max
SELECT 
	AVG(days_first_to_second_session) AS avg_days_first_to_second
    , MIN(days_first_to_second_session) AS min_days_first_to_second
    , MAX(days_first_to_second_session) AS max_days_first_to_second
FROM user_first_to_second;

-- Interesting to see that our repeat visitors are coming back about a month later, on average.
-- NEXT STEPS:
-- Investigate the channels that these visitors are using.


/*
Analyzing Repeat Channel Behavior
- See if it's all direct type-in, or if we're paying for these customers with paid search ads multiple times
- Compare new vs. repeat sessions by channel
- Use time period since 2014 to date ('2014-11-05')
*/
SELECT * FROM website_sessions
WHERE utm_source = 'socialbook';

CREATE TEMPORARY TABLE channel_groups
SELECT 
	user_id
    , website_session_id
    , is_repeat_session
    , CASE 
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
        END AS channel_group
FROM website_sessions
WHERE 
	created_at >= '2014-01-01'
    AND created_at < '2014-11-05';


SELECT 
	channel_group
    , COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions
    , COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM channel_groups
GROUP BY 1
ORDER BY 3 DESC;

-- when customers come back for repeat visits, they come mainly through 'organic search', 'direct type-in' and 'paid brand'.
-- Only about 1/3 come through a paid channel, and brand clicks are cheaper than paid nonbrand campaigns.
-- So, we are not paying very much for these subsequent visits



/*
Analyzing New & Repeat Conversion Rates
- Make comparison of conversion rates and revenue per session for repeat sessions vs new sessions
- Use data from 2014, to date ('2014-11-08')
*/

SELECT 
	S.is_repeat_session AS is_repeat_session
    , COUNT(DISTINCT S.website_session_id) AS sessions
    -- , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id)*100 AS conv_rate
    -- , SUM(O.price_usd) AS revenue
    , SUM(O.price_usd) / COUNT(DISTINCT S.website_session_id) As rev_per_session
FROM website_sessions S
	LEFT JOIN orders O
		ON S.website_session_id = O.website_session_id
WHERE S.created_at >= '2014-01-01' 
	AND S.created_at < '2014-11-08'
GROUP BY 1;

-- The repeat sessions are more likely to convert to orders,
-- and they also generate a little bit more revenue per session
-- Customers who are more familiar with your company have already been purchasing a little bit more