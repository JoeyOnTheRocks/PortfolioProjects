-- Advanced MYSQL Mid Course Project
USE mavenfuzzyfactory;

/*
1. Gsearch seems to be the biggest driver of our business. 
Could you pull monthly trends for gsearch sessions
and orders so that we can showcase the growth there?
*/
SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source = 'gsearch'
GROUP BY 1,2;


/*
2. Next, it would be great to see a similar monthly trend for Gsearch, 
but this time splitting out nonbrand and brand campaigns separately. 
I am wondering if brand is picking up at all. If so, this is a good story to tell.
*/
SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_sesession_if ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source = 'gsearch'
GROUP BY 1,2;


/*
3. While we’re on Gsearch, could you dive into nonbrand, 
and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and 
show the board we really know our traffic sources.
*/
SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'desktop' THEN website_sessions.website_sesession_if ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1,2;


/*
4. I’m worried that one of our more pessimistic board members may be concerned about 
the large % of traffic from Gsearch. Can you pull monthly trends for Gsearch, 
alongside monthly trends for each of our other channels?
*/
-- Find utm sources and referers to see traffic
SELECT DISTINCT
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';

SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_sesession_if ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN orders.order_id ELSE NULL END) AS bsearch_paid_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;

/*
5. I’d like to tell the story of our website performance improvements 
over the course of the first 8 months.
Could you pull session to order conversion rates, by month ?
*/
SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;


/*
6. For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 Jul 28), 
and use nonbrand sessions and revenue since then to calculate incremental value)
*/
-- Find first instance of pageview id
SELECT
	MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- Create temp table for first_test_pv
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_sessions.created_at < '2012-07-28'
        AND website_pageviews.website_pageview_id >= 23504
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id;
    
-- Bring in landing page, restricting to home or lander-1
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

-- Bring in orders
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT
	nonbrand_test_sessions_w_landing_pages.website_session_id,
    nonbrand_test_sessions_w_landing_pages.landing_page,
    orders.order_id
FROM nonbrand_test_sessions_w_landing_pages
	LEFT JOIN orders
		ON nonbrand_test_sessions_w_landing_pages.website_session_id = orders.website_session_id;
        
-- Find difference between conversion rates
SELECT
	landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_sessions_w_orders
GROUP BY 1;
-- 0.0318 for home vs 0.0406 for lander-1
-- 0.0086

-- Find most recent pageview for gsearch nonbrand where traffic was sent to /home
SELECT
	MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
    AND website_sessions.created_at < '2012-11-27';
-- max website_session_id = 17145

-- Find sessions since test
SELECT
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-17'
	AND website_session_id > 17145
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';


/*
7. For the landing page test you analyzed previously, 
it would be great to show a full conversion funnel from each of the two pages to orders . 
You can use the same time period you analyzed last time (Jun 19 Jul 28).
*/
CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT
	website_session_id,
    MAX(homepage) AS saw_homepage,
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at,
	CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
	CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at
) AS pageview_level
GROUP BY 
	website_session_id;
    
-- Final output part 1
SELECT
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'check logic'
	END AS segment,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flagged
GROUP BY 1;

-- Final output part 2
SELECT
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'check logic'
	END AS segment,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_click_rt,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_level_made_it_flagged
GROUP BY 1;

/*
8. I’d love for you to quantify the impact of our billing test, as well. 
Please analyze the lift generated from the test (Sep 10 Nov 10), 
in terms of revenue per billing page session, 
and then pull the number of billing page sessions
for the past month to understand monthly impact.
*/
-- Quantify lander test
SELECT
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
FROM (
SELECT
	website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_version_seen,
    orders.order_id,
    orders.price_usd
FROM website_pageviews
	LEFT JOIN orders
		ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at > '2012-09-10'
	AND website_pageviews.created_at < '2012-11-10'
    AND website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_pageviews_and_order_data
GROUP BY 1;

-- Month difference
SELECT
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2')
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27';