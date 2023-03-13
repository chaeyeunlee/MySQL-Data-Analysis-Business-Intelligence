/*
BUSINESS CONCEPT : PRODUCT SALES ANALYSIS
- Analyzing product sales can help you understand how each product is contributing to your business 
	and how new product launches impact the overall portfolio

COMMON USE CASES:
1. Analyzing sales and revenue by product
2. Monitoring the impact of adding a new product to your product portfolio
3. Watching product sales trends to understand the overall health of your business

KEY BUSINESS TERMS 
1. Orders: number of orders placed by customers 
	- COUNT(DISTINCT order_id)
2. Revenue: money the business brings in from orders 
	- SUM(price_usd)
3. Margin: revenue less the cost of good sold 
	- SUM(price_usd-cogs_usd)
4. Average Order Value (AOV): average revenue generated per order 
	- AVG(price_usd)
*/

SELECT * FROM orders;
-- 'primary_product_id' corresponds to the first product the customer placed in their cart
-- 'items_purchased is the total number of items purchased

SELECT 
	primary_product_id
    , COUNT(order_id) AS orders
    , SUM(price_usd) AS revenue
    , SUM(price_usd - cogs_usd) AS margin
    , AVG(price_usd) AS aov
FROM orders
GROUP BY 1
ORDER BY 1;
-- interestingly, the average order value(AOV) is a little bit higher for product 2 and it's a little bit lower for product 3

/*
Product-Level Sales Analysis
- We're about to launch a new product, and would like to do a deep dive on our current flagship product.
- Pull monthly trends to date ('2013-01-04') for number of sales, total revenue, and total margin generated for the business
*/
SELECT 
	YEAR(created_at) AS yr
    , MONTH(created_at) AS mo
    , COUNT(DISTINCT order_id) AS number_of_sales
    , SUM(price_usd) AS total_revenue
    , SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1,2;

-- This will serve as baseline data so that we can see how our revenue and margin evolve 
-- as we roll out the new product.


/*
Analyzing Product Launches
- We launched our second product back on '2013-01-06'
- Pull together some trended analysis
- Show monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by product
- For the time period since '2012-04-01' before '2013-04-05'
*/
SELECT DISTINCT 
		primary_product_id
        , items_purchased
FROM orders
WHERE created_at < '2013-04-05';


SELECT 
	YEAR(S.created_at) AS yr
    , MONTH(S.created_at) AS mo
    , COUNT(DISTINCT S.website_session_id) AS sessions
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id) *100 AS 'conv_rate(%)'
    , SUM(O.price_usd)/COUNT(DISTINCT S.website_session_id) AS revenue_per_session
    , COUNT(DISTINCT CASE WHEN O.primary_product_id = 1 THEN O.order_id ELSE NULL END) AS product_one_orders
    , COUNT(DISTINCT CASE WHEN O.primary_product_id = 2 THEN O.order_id ELSE NULL END) AS product_two_orders
FROM website_sessions S
	LEFT JOIN orders O
    ON S.website_session_id = O.website_session_id
WHERE S.created_at > '2012-04-01' 
	AND S.created_at < '2013-04-01'
GROUP BY 1,2;

-- The conversion rate and revenue per session are improving over time, which is great!
-- It's hard to tell if the new product launch is what caused the improvement in the recent months
-- 	or if this is just a continuation of the overall business improvement that we've been seeing all year.



/*
BUSINESS CONCEPT: PRODUCT LEVEL WEBSITE ANALYSIS 
: Product-focused website analysis is about learning 
	- how customers interact with each of your products
    - how well each product converts customers
    
COMMON USE CASES:
1. Understanding which of your products generate the most interest on multi-product showcases pages
2. Analyzing the impact on website conversion rates when you add a new product
3. Building product-specific conversion funnels to understand whether certain products convert better than others

*/

-- product 1: /the-original-mr-fuzzy
-- product 2: /the-forever-love-bear
SELECT 
    P.pageview_url
    , COUNT(DISTINCT P.website_session_id) AS sessions
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id)/COUNT(DISTINCT P.website_session_id)*100 AS 'viewed_product_to_order_rate(%)'
FROM website_pageviews P
	LEFT JOIN orders O
    ON P.website_session_id = O.website_session_id
WHERE 
	P.created_at BETWEEN '2013-02-01' AND '2013-03-01' -- arbitrary
	AND P.pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
GROUP BY 1;

/*
Product-Level Website Pathing / Product Pathing Analysis
- About user path and conversion funnel
- Look at sessions which hit the '/products' page and see where they went next

- Pull clickthrough rates from '/products' page since the new product launch on '2013-01-06' by product
- Compare to the 3 months leading up to launch as a baseline
*/

-- STEP 1: find the relevant '/products' pageviews with website_session_id
-- STEP 2: find the next pageview id that occurs AFTER the product pageview
-- STEP 3: find the pageview_url associated with any applicable next pageview id
-- STEP 4: summarize the data and analyze the pre vs post periods


SELECT DISTINCT pageview_url
FROM website_pageviews;

-- STEP 1: find the relevant '/products' pageviews with website_session_id
CREATE TEMPORARY TABLE products_pageviews
SELECT 
	website_session_id
    , website_pageview_id
    , created_at
    , CASE 
		WHEN created_at < '2013-01-06' THEN 'A.Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN 'B.Post_Product_2'
        ELSE 'uh oh...check logic'
		END AS time_period
FROM website_pageviews
WHERE created_at >'2012-10-06' -- start of 3 months before product 2 launch
	AND created_at < '2013-04-06' 
    AND pageview_url = '/products';
    
SELECT * FROM products_pageviews;

-- STEP 2: find the next pageview id that occurs AFTER the product pageview
CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT 
	P.time_period
    , P.website_session_id
    , MIN(W.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews P
	LEFT JOIN website_pageviews W
    ON P.website_session_id = W.website_session_id
    AND P.website_pageview_id < W.website_pageview_id
GROUP BY 1,2;

SELECT * FROM sessions_w_next_pageview_id;

-- STEP 3: find the pageview_url associated with any applicable next pageview id
CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT 
	N.time_period
    , N.website_session_id
    , P.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id N
	LEFT JOIN website_pageviews P
    ON N.min_next_pageview_id = P.website_pageview_id;
    
SELECT * FROM sessions_w_next_pageview_url;

-- STEP 4: summarize the data and analyze the pre vs post periods
SELECT 
	time_period
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg
    , COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id)*100 AS pct_w_next_pg
	, COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy
    , COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id)*100 AS pct_to_mrfuzzy
	, COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear
    , COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id)*100 AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY time_period;

-- the percent of '/product' pageviews that clicked to 'mr.fuzzy' has gone down since the launch of the 'love bear'
-- but the overall clickthrough rate has gone up
-- so it seems to be generating additional product interest overall.

-- NEXT STEPS:
-- Look at the conversion funnels for each product individually (product-specific conversion funnels)

/*
Building Product-Level Conversion Funnels
- Analyze the conversion funnels from each product page to conversion.
- Produce a comparison between the two conversion funnels, for all website traffic.
*/

SELECT DISTINCT pageview_url
FROM website_pageviews;

-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: figure out which pageview urls to look for
-- STEP 3: pull all pageviews and identify the funnel steps
-- STEP 4: create the session-level conversion funnel view
-- STEP 5: aggregate the data to assess funnel performance


-- STEP 1: select all pageviews for relevant sessions
CREATE TEMPORARY TABLE sessions_seeing_product_page
SELECT
	website_session_id
    , website_pageview_id
    , pageview_url AS product_page_seen
FROM website_pageviews
WHERE 
	created_at > '2013-01-06' -- product 2 launch
    AND created_at < '2013-04-10' -- date of assignment
	AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear');

SELECT * FROM sessions_seeing_product_page;

-- STEP 2: figure out which pageview urls to look for
-- finding the right pageview_url to build the funnels
SELECT DISTINCT
	P.pageview_url
FROM sessions_seeing_product_page S
	LEFT JOIN website_pageviews P
    ON S.website_session_id = P.website_session_id
    AND S.website_pageview_id < P.website_pageview_id;
    
-- STEP 3: pull all pageviews and identify the funnel steps    
    
-- we'll look at the inner query first to look over the pageview-level results -> step 3
-- then, turn it into a subquery and make it the summary with flags -> step 4

SELECT
	 S.website_session_id
     , S.product_page_seen
     , CASE WHEN P.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
     , CASE WHEN P.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
     , CASE WHEN P.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page
     , CASE WHEN P.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_page S
	LEFT JOIN website_pageviews P
		ON S.website_session_id = P.website_session_id
		AND S.website_pageview_id < P.website_pageview_id
ORDER BY
	S.website_session_id,
    P.created_at
;

-- STEP 4: create the session-level conversion funnel view

CREATE TEMPORARY TABLE session_product_level_made_it_flag
SELECT 
	website_session_id
    , CASE 
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'uh oh...check logic'
        END AS product_seen
	, MAX(cart_page) AS cart_made_it
    , MAX(shipping_page) AS shipping_made_it
    , MAX(billing_page) AS billing_made_it
    , MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
	 S.website_session_id
     , S.product_page_seen
     , CASE WHEN P.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
     , CASE WHEN P.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page
     , CASE WHEN P.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page
     , CASE WHEN P.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_page S
	LEFT JOIN website_pageviews P
		ON S.website_session_id = P.website_session_id
		AND S.website_pageview_id < P.website_pageview_id
ORDER BY
	S.website_session_id,
    P.created_at
) AS pageview_level
GROUP BY 1,2;

SELECT * FROM session_product_level_made_it_flag;
    

-- STEP 5: aggregate the data to assess funnel performance
-- final output part 1
SELECT 
	product_seen
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart
    , COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping
    , COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing
    , COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flag
GROUP BY 1;

-- final output part 2 : click rates
SELECT 
	product_seen
    , COUNT(DISTINCT website_session_id) AS sessions
    , COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT website_session_id)*100 AS product_page_click_rate
    , COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)*100 AS cart_click_rate
    , COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)*100 AS shipping_click_rate
    , COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)*100 AS billing_click_rate
FROM session_product_level_made_it_flag
GROUP BY 1;

-- Adding a second product increased overall CTR (click through rate) from the '/products' page
-- The love bear has a better click rate to the '/cart' page and comparable rates throughout the rest of the funnel.
-- Seems like the second product was a great addition for our business.


/*
BUSINESS CONCEPT: CROSS-SELLING & PRODUCT PORTFOLIO ANALYSIS
: cross-sell analysis is all about understanding 
	- which products users are most likely to purchase together
    - offering smart product recommendations to maximize our revenue

COMMON USE CASES:
1. Understanding which products are often purchased together
2. Testing and optimizing the way you cross-sell products on your website
3. Understanding the conversion rate impact and the overall revenue impact of trying to cross-sell additional products

*/

SELECT * FROM order_items
WHERE  order_id BETWEEN 10000 AND 11000;

SELECT 
	O.primary_product_id
    , I.product_id AS cross_sell_product
    , COUNT(DISTINCT O.order_id) AS orders
FROM orders O
	LEFT JOIN order_items I
    ON O.order_id = I.order_id
    AND I.is_primary_item = 0 -- cross sell only
GROUP BY 1,2;

SELECT 
	O.primary_product_id
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT CASE WHEN I.product_id = 1 THEN O.order_id ELSE NULL END) AS x_sell_prod1
    , COUNT(DISTINCT CASE WHEN I.product_id = 2 THEN O.order_id ELSE NULL END) AS x_sell_prod2
    , COUNT(DISTINCT CASE WHEN I.product_id = 3 THEN O.order_id ELSE NULL END) AS x_sell_prod3
    , COUNT(DISTINCT CASE WHEN I.product_id = 4 THEN O.order_id ELSE NULL END) AS x_sell_prod4
    
    , COUNT(DISTINCT CASE WHEN I.product_id = 1 THEN O.order_id ELSE NULL END) 
		/ COUNT(DISTINCT O.order_id)*100 AS x_sell_prod1_rate
    , COUNT(DISTINCT CASE WHEN I.product_id = 2 THEN O.order_id ELSE NULL END) 
		/ COUNT(DISTINCT O.order_id)*100 AS x_sell_prod2_rate
    , COUNT(DISTINCT CASE WHEN I.product_id = 3 THEN O.order_id ELSE NULL END) 
		/ COUNT(DISTINCT O.order_id)*100 AS x_sell_prod3_rate
    , COUNT(DISTINCT CASE WHEN I.product_id = 4 THEN O.order_id ELSE NULL END) 
		/ COUNT(DISTINCT O.order_id)*100 AS x_sell_prod4_rate
FROM orders O
	LEFT JOIN order_items I
    ON O.order_id = I.order_id
    AND I.is_primary_item = 0 -- cross sell only
GROUP BY 1;




/*
Cross-Sell Analysis
- On '2013-09-25' we started giving customers the option to add a second product while on the '/cart' page.
- Compare the month before vs the month after the change
- Show CTR from the '/cart' page, Avg Products per Order, AOV, and overall revenue per '/cart' page view.
*/

-- STEP 1: Identify the relevant '/cart' page views and their sessions
-- STEP 2: See which of those '/cart' sessions clicked through to the shipping page
-- STEP 3: Find the orders associated with the '/cart' sessions. Analyze products purchased, AOV
-- STEP 4: Aggregate and analyze a summary of our findings


-- STEP 1: Identify the relevant '/cart' page views and their sessions
CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT 
	CASE 
		WHEN created_at < '2013-09-25' THEN 'A.Pre_Cross_Sell'
        WHEN created_at >= '2013-01-06' THEN 'B.Post_Cross_Sell'
        ELSE 'uh oh...check logic'
        END AS time_period
	, website_session_id AS cart_session_id
    , website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE 
	created_at BETWEEN '2013-08-25' AND '2013-10-25'
    AND pageview_url = '/cart';

SELECT * FROM sessions_seeing_cart;
    
-- STEP 2: See which of those '/cart' sessions clicked through to the shipping page
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT 
	C.time_period
    , C.cart_session_id
    , MIN(P.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart C
	LEFT JOIN website_pageviews P
    ON C.cart_session_id = P.website_session_id
    AND C.cart_pageview_id < P.website_pageview_id
GROUP BY 1,2
HAVING 
	MIN(P.website_pageview_id) IS NOT NULL;

SELECT * FROM cart_sessions_seeing_another_page;

-- STEP 3: Find the orders associated with the '/cart' sessions. Analyze products purchased, AOV
CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
	time_period
    , cart_session_id
    , order_id
    , items_purchased
    , price_usd
FROM sessions_seeing_cart 
	INNER JOIN orders
    ON sessions_seeing_cart.cart_session_id = orders.website_session_id
;

SELECT * FROM pre_post_sessions_orders;


-- STEP 4: Aggregate and analyze a summary of our findings
-- first, we'll look at this select statement
-- then we'll turn it into subquery

SELECT 
	C.time_period
    , C.cart_session_id
    , CASE WHEN A.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page
    , CASE WHEN O.order_id IS NULL THEN 0 ELSE 1 END AS placed_order
    , O.items_purchased
    , O.price_usd
FROM sessions_seeing_cart C
	LEFT JOIN cart_sessions_seeing_another_page A
		ON C.cart_session_id = A.cart_session_id
	LEFT JOIN pre_post_sessions_orders O
		ON C.cart_session_id = O.cart_session_id
ORDER BY C.cart_session_id;

SELECT 
	time_period
    , COUNT(DISTINCT cart_session_id) AS cart_sessions
    , SUM(clicked_to_another_page) AS clickthroughs
    , SUM(clicked_to_another_page) / COUNT(DISTINCT cart_session_id) AS cart_ctr -- clickthrough rate
    -- , SUM(placed_order) AS orders_placed
    -- , SUM(items_purchased) AS products_purchased
    , SUM(items_purchased) / SUM(placed_order) AS products_per_order
    -- , SUM(price_usd) AS revenue
    , SUM(price_usd) / SUM(placed_order) AS aov -- average order value
    , SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM(
SELECT 
	C.time_period
    , C.cart_session_id
    , CASE WHEN A.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page
    , CASE WHEN O.order_id IS NULL THEN 0 ELSE 1 END AS placed_order
    , O.items_purchased
    , O.price_usd
FROM sessions_seeing_cart C
	LEFT JOIN cart_sessions_seeing_another_page A
		ON C.cart_session_id = A.cart_session_id
	LEFT JOIN pre_post_sessions_orders O
		ON C.cart_session_id = O.cart_session_id
ORDER BY 
	C.cart_session_id
) AS full_data

GROUP BY time_period;

-- products per order, AOV, and revenue per cart session are all up slightly since the cross-sell feature was added.


/*
Product Portfolio Expansion
- On '2013-12-12' we launched a thrid product targeting the birthday gift market (Birthday Bear)
- Run a pre-post anaysis comparing the month before vs the month after, 
	in terms of session-to-order conversion rate, AOV, products per order, and revenue per session
*/

SELECT 
	CASE 
		WHEN S.created_at < '2013-12-12' THEN 'A.Pre_Birthday_Bear'
        WHEN S.created_at >= '2013-12-12' THEN 'B.Post_Birthday_Bear'
        ELSE 'uh oh...check logic'
        END AS time_period
	, COUNT(DISTINCT S.website_session_id) AS sessions
    , COUNT(DISTINCT O.order_id) AS orders
    , COUNT(DISTINCT O.order_id) / COUNT(DISTINCT S.website_session_id)*100 AS 'conv_rate(%)'
    , SUM(O.price_usd) AS total_revenue
    , SUM(O.price_usd) / COUNT(DISTINCT O.order_id) AS average_order_value
    , SUM(O.items_purchased) AS total_products_sold
    , SUM(O.items_purchased) / COUNT(DISTINCT O.order_id) AS products_per_order
    , SUM(O.price_usd) / COUNT(DISTINCT S.website_session_id) AS revenue_per_session
    
FROM website_sessions S
	LEFT JOIN orders O
		ON S.website_session_id = O.website_session_id
WHERE S.created_at BETWEEN '2013-11-12' AND '2014-01-12'

GROUP BY 1;

-- All of our critical metrics have improved since we launched the third product!!



/*
BUSINESS CONCEPT: PRODUCT REFUND RATES 
: Analyzing product refund is all about controlling for quality and understanding where you might have problems to address

COMMON USE CASES:
1. Monitoring products from different suppliers
	 - sometimes certain supplier will have problems with quality
     - refund rates can be very good indicator of that quality
2. Understanding refund rates for products at different price points
3. Taking product refund rates and the associated costs into account when assessing the overall performance of your business

*/


/*
Analyzing Product Refund Rates
- Mr.Fuzzy supplier had some quality issues which weren't corrected until '2013-09'
- Then they had a major problem where the bears' arms were falling off in Aug/Sep 2014.
- As a result, We replaced them with a new supplier on '2014-09-16'

- Pull monthly product refund rates by products, and confirm our quality issues are now fixed
*/
SELECT *
FROM order_items I
	LEFT JOIN order_item_refunds R
		ON I.order_id = R.order_id;


SELECT 
	YEAR(O.created_at) AS yr
    , MONTH(O.created_at) AS mo
    , COUNT(DISTINCT CASE WHEN O.product_id = 1 THEN O.order_item_id ELSE NULL END) AS p1_orders
    , COUNT(DISTINCT CASE WHEN O.product_id = 1 THEN R.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN O.product_id = 1 THEN O.order_item_id ELSE NULL END)*100 AS p1_refund_rt
    , COUNT(DISTINCT CASE WHEN O.product_id = 2 THEN O.order_item_id ELSE NULL END) AS p2_orders
    , COUNT(DISTINCT CASE WHEN O.product_id = 2 THEN R.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN O.product_id = 2 THEN O.order_item_id ELSE NULL END)*100 AS p2_refund_rt
    , COUNT(DISTINCT CASE WHEN O.product_id = 3 THEN O.order_item_id ELSE NULL END) AS p3_orders
    , COUNT(DISTINCT CASE WHEN  O.product_id = 3 THEN R.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN O.product_id = 3 THEN O.order_item_id ELSE NULL END)*100 AS p3_refund_rt
    , COUNT(DISTINCT CASE WHEN O.product_id = 4 THEN O.order_item_id ELSE NULL END) AS p4_orders
    , COUNT(DISTINCT CASE WHEN  O.product_id = 4 THEN R.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN O.product_id = 4 THEN O.order_item_id ELSE NULL END)*100 AS p4_refund_rt
FROM order_items O
	LEFT JOIN order_item_refunds R
		ON O.order_id = R.order_id
WHERE O.created_at < '2014-10-15'
GROUP BY 1,2;

