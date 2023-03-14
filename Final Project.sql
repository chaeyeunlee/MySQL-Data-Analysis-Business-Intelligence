/*
THE SITUATION
: Now that we've been in market for 3 years, we've generated enough growth to raise a much larger raound of venture capital 	
funding. We're close to securing a large round from one of the best West Coast firms.

THE OBJECTIVES:
1. Tell the story of your company's growth, using trended performance data
2. Use the database to explain how you've been able to produce growth, 
	by diving into channels and website optimizations
3. Flex your analytical muscles so the VCs know your company is a serious data-driven shop
*/

USE mavenfuzzyfactory;

/*
1. First, I’d like to show our volume growth. Can you pull overall session and order volume, 
trended by quarter for the life of the business? Since the most recent quarter is incomplete, 
you can decide how to handle it.
*/ 
SELECT
	YEAR(S.created_at) AS yr
    , QUARTER(S.created_at) AS qtr
    , COUNT(DISTINCT S.website_session_id) AS total_sessions
    , COUNT(DISTINCT O.order_id) AS total_orders
    , ROUND(COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id)*100,2) AS 'conv_rate(%)'
FROM website_sessions S
	LEFT JOIN orders O
		ON S.website_session_id = O.website_session_id
GROUP BY 1,2
ORDER BY 1,2;


/*
2. Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures 
since we launched, for session-to-order conversion rate, revenue per order, and revenue per session. 
*/
SELECT 
	YEAR(S.created_at) AS yr
    , QUARTER(S.created_at) AS qtr
    , ROUND(COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id)*100,2) AS conv_rate
    , ROUND(SUM(O.price_usd) / COUNT(DISTINCT O.order_id),2) AS rev_per_order
    , ROUND(SUM(O.price_usd) / COUNT(DISTINCT S.website_session_id),2) AS rev_per_session
FROM website_sessions S
	LEFT JOIN orders O
		ON S.website_session_id = O.website_session_id
GROUP BY 1,2
ORDER BY 1,2;



/*
3. I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders 
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?
*/
SELECT 
	YEAR(O.created_at) AS yr
    , QUARTER(O.created_at) AS qtr
    , COUNT(DISTINCT CASE WHEN S.utm_source = 'gsearch' AND S.utm_campaign = 'nonbrand' THEN O.order_id ELSE NULL END) AS gsearch_nonbrand_orders
    , COUNT(DISTINCT CASE WHEN S.utm_source = 'bsearch' AND S.utm_campaign = 'nonbrand' THEN O.order_id ELSE NULL END) AS bsearch_nonbrand_orders
    , COUNT(DISTINCT CASE WHEN S.utm_campaign = 'brand' THEN O.order_id ELSE NULL END) AS brand_search_orders
    , COUNT(DISTINCT CASE WHEN S.utm_source IS NULL AND S.http_referer IS NOT NULL THEN O.order_id ELSE NULL END) AS organic_search_orders
    , COUNT(DISTINCT CASE WHEN S.utm_source IS NULL AND S.http_referer IS NULL THEN O.order_id ELSE NULL END) AS direct_type_in_orders
FROM orders O
	LEFT JOIN website_sessions S
		ON O.website_session_id = S.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

-- The business has become much less dependent on their paid gsearch/bsearch nonbrand campaigns,
-- and is starting to build its own brand, organic and direct type-in traffic
-- , which has better margin and take business out of dependecny of search engine.


/*
4. Next, let’s show the overall session-to-order conversion rate trends for those same channels, 
by quarter. Please also make a note of any periods where we made major improvements or optimizations.
*/
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt, 
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rt, 
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rt,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv_rt,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_conv_rt
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;


/*
5. We’ve come a long way since the days of selling a single product. Let’s pull monthly trending for revenue 
and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
*/
SELECT
	YEAR(created_at) AS yr, 
    MONTH(created_at) AS mo, 
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS lovebear_marg,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS birthdaybear_marg,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS minibear_marg,
    SUM(price_usd) AS total_revenue,  
    SUM(price_usd - cogs_usd) AS total_margin
FROM order_items 
GROUP BY 1,2
ORDER BY 1,2
;

-- For product 1 (mr fuzzy), there's a rush leading up to the holiday season at the end of the year (in November and December 2012)
-- And we see that repeated each year

-- For product 2 (love bear), we see a large spike in revenue around the Valentine's Day holiday (in February).
-- This bear was targeted to couples for giving to one another as a gift. 

-- For product 3 (birthday bear), we may see some similar trends with a spike at the end of the year.
-- Look like there's a little bit of a pop at the end of the year.
-- But it's hard to tell because we don't have as much data to understand seasonality.

-- Same thing in product 4 (mini bear), there's a little bit of a pop.




/*
6. Let’s dive deeper into the impact of introducing new products. Please pull monthly sessions to 
the /products page, and show how the % of those sessions clicking through another page has changed 
over time, along with a view of how conversion from /products to placing an order has improved.
*/

-- first, identifying all the views of the /products page
CREATE TEMPORARY TABLE products_pageviews
SELECT 
	website_session_id
    , website_pageview_id
    , created_at AS saw_product_page_at
FROM website_pageviews
WHERE pageview_url = '/products';


SELECT
	YEAR(P.saw_product_page_at) AS yr
    , MONTH(p.saw_product_page_at) AS mo
    , COUNT(DISTINCT P.website_session_id) AS sessions_products_page
    , COUNT(DISTINCT W.website_session_id) AS clicked_to_next_page
    , COUNT(DISTINCT W.website_session_id) / COUNT(DISTINCT P.website_session_id)*100 AS clickthrough_rate
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id) / COUNT(DISTINCT P.website_session_id)*100 AS products_to_order_rate
    
FROM products_pageviews P
	LEFT JOIN website_pageviews W
		ON P.website_session_id = W.website_session_id
        AND P.website_pageview_id < W.website_pageview_id
        
	LEFT JOIN orders O
		ON P.website_session_id = O.website_session_id
        
GROUP BY 1,2
ORDER BY 1,2;

-- Clickthrough rate has been going up from around 71% at the beginning of the business to 85% in the most recent month.
-- Similarly, the rate of people seeing the product page and then converting to a full paying order
-- 		has gone up from 6-8% all the way up to around 14% in the most recent month.
-- So, all of these improvements that the business has made, adding additional products that may appeal better to customers,
-- 		bringing in a product at a lower price point, this has really impacted the percentage of customers that are clicking through on the product page 
-- 		in a positive way.
-- And similarly, it's really impacted the conversion rate ot an order from the product page.



/*
7. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item). 
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/

CREATE TEMPORARY TABLE primary_products
SELECT 
	order_id, 
    primary_product_id, 
    created_at AS ordered_at
FROM orders 
WHERE created_at > '2014-12-05' -- when the 4th product was added (says so in question)
;

-- Cross-Sell Analysis
SELECT
	primary_products.*, 
    order_items.product_id AS cross_sell_product_id
FROM primary_products
	LEFT JOIN order_items 
		ON order_items.order_id = primary_products.order_id
        AND order_items.is_primary_item = 0; -- only bringing in cross-sells;




SELECT 
	primary_product_id, 
    COUNT(DISTINCT order_id) AS total_orders, 
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM
(
SELECT
	primary_products.*, 
    order_items.product_id AS cross_sell_product_id
FROM primary_products
	LEFT JOIN order_items 
		ON order_items.order_id = primary_products.order_id
        AND order_items.is_primary_item = 0 -- only bringing in cross-sells
) AS primary_w_cross_sell
GROUP BY 1;

-- Looks like product 4 cross-sold pretty well to product 1, to product 2, and to product 3
-- above 20 percent of the orders for primary product
-- that's perhaps because product 4 was at the lower price point.
-- Maybe product 4 is a major contributor to the higher average order value.







