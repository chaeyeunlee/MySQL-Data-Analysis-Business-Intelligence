/*
BUSINESS CONCEPT : ANALYZING SEASONALITY & BUSINESS PATTERNS
- Analyzing business patterns is all about generating insights to help you maximize efficiency and anticipate future trends

COMMON USE CASES:
1. Day-parting analysis to understand how much support staff you should have at different times of day or on different days of the week
2. Analyzing seasonality to better prepare for upcoming spikes or slowdowns in demand

* MySQL date functions
- QUARTER() : return the quarter for a given date - qtr
- MONTH() : return the month for a given date - mo
- WEEK() : return the week for a given date - wk
- DATE() : return the date for a given date - date
- WEEKDAY() : return 0-6, corresponding to Mon-Sun (0 = Mon, 1 = Tue , etc) - wkday
- HOUR() : return the hour for a given date - hr
*/


/*
Analyzing Seasonality
- Take a look at 2012's monthly and weekly volume patterns
	to see if we can find any seasonal treands we should plan for in 2013
- Pull session volume and order volume in 2012
*/

-- 1. 2012's monthly trends
SELECT
	YEAR(S.created_at) AS yr
    , MONTH(S.created_at) AS mo
    , COUNT(DISTINCT S.website_session_id) AS sessions
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id)/COUNT(DISTINCT S.website_session_id)*100 AS 'conv_rate(%)'
FROM website_sessions S
	LEFT JOIN orders O
    ON S.website_session_id = O.website_session_id
WHERE S.created_at < '2013-01-01'
GROUP BY 1,2;

-- November looks like it's the peak season with 14,020 sessions, 618 orders.

-- 2. 2012's weekly trends
SELECT
	-- YEAR(S.created_at) AS yr,
    -- WEEK(S.created_at) AS wk,
    MIN(DATE(S.created_at)) AS week_start_date
    , COUNT(DISTINCT S.website_session_id) AS sessions
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id)/COUNT(DISTINCT S.website_session_id)*100 AS 'conv_rate(%)'
FROM website_sessions S
	LEFT JOIN orders O
    ON S.website_session_id = O.website_session_id
WHERE S.created_at < '2013-01-01'
GROUP BY YEARWEEK(S.created_at);

-- from the week of the 11th,November to the week of the 18th,November, we see a doubling of our order volume.
-- that's definitely something we'd want to look into some more.
-- And for the end of the year, remains pretty high, but not quite as high as these two weeks.

-- Overall, we grew fairly steadily all year, and saw significant volume around the holiday months
-- 		especially the weeks of Black Friday and Cyber Monday
-- We'll want to keep this surge in mind in 2013 as we think about customer support and inventory management!!!
-- 		to stock up on inventory ahead of that so that we can fill the demand.

/*
Analyzing Business Patterns : Customer Service Data
- We're considering adding live chat support to the website to improve our customer experience
- Analyze the average website session volume, by hour of day and by day week 
	so that we can staff appropriately
- Use a date range of '2012-09-15' - '2012-11-15' to avoid the holiday time period
*/

-- My Answer
CREATE TEMPORARY TABLE hr_wkday_sessions
SELECT 
	date
    , hr
    , CASE 
		WHEN WEEKDAY(date) = 0 THEN 'mon'
		WHEN WEEKDAY(date) = 1 THEN 'tue'
		WHEN WEEKDAY(date) = 2 THEN 'wed'
		WHEN WEEKDAY(date) = 3 THEN 'thu'
		WHEN WEEKDAY(date) = 4 THEN 'fri'
		WHEN WEEKDAY(date) = 5 THEN 'sat'
		WHEN WEEKDAY(date) = 6 THEN 'sun'
		END AS wkday
	, sessions
FROM(
SELECT 
	DATE(created_at) AS date
	, HOUR(created_at) AS hr
    , COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2
) AS date_hr_sessions;

SELECT * FROM hr_wkday_sessions;

SELECT 
	hr
    , ROUND(AVG(CASE WHEN wkday = 'mon' THEN sessions ELSE NULL END),1) AS mon
    , ROUND(AVG(CASE WHEN wkday = 'tue' THEN sessions ELSE NULL END),1) AS tue
    , ROUND(AVG(CASE WHEN wkday = 'wed' THEN sessions ELSE NULL END),1) AS wed
	, ROUND(AVG(CASE WHEN wkday = 'thu' THEN sessions ELSE NULL END),1) AS thu
    , ROUND(AVG(CASE WHEN wkday = 'fri' THEN sessions ELSE NULL END),1) AS fri
    , ROUND(AVG(CASE WHEN wkday = 'sat' THEN sessions ELSE NULL END),1) AS sat
    , ROUND(AVG(CASE WHEN wkday = 'sun' THEN sessions ELSE NULL END),1) AS sun
FROM hr_wkday_sessions
GROUP BY 1
ORDER BY 1;


-- Solution
SELECT 
	hr
    , ROUND(AVG(website_sessions),1) AS avg_sessions
	, ROUND(AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END),1) AS mon
    , ROUND(AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END),1) AS tue
    , ROUND(AVG(CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END),1) AS wed
    , ROUND(AVG(CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END),1) AS thu
    , ROUND(AVG(CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END),1) AS fri
    , ROUND(AVG(CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END),1) AS sat
    , ROUND(AVG(CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END),1) AS sun
FROM(
SELECT 
	DATE(created_at) AS created_date
    , WEEKDAY(created_at) AS wkday
	, HOUR(created_at) AS hr
    , COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3
) AS daily_hourly_sessions
GROUP BY 1
ORDER BY 1;

-- ~10 sessions per hour per employee staffed is about right
-- Looks like we can plan on one support staff around the clock 
-- Then, we should double up to two staff members from 8am to 5pm Monday through Friday.
