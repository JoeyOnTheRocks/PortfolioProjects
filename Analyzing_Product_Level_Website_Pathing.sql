USE mavenfuzzyfactory;
-- Analyzing Product Level Website Pathing
-- TIP: Use temp tables

-- Example
SELECT DISTINCT
	pageview_url
FROM website_pageviews
WHERE created_at BETWEEN '2013-02-01' AND '2013-03-01';

-- Looking at products specifically
SELECT DISTINCT
	-- website_session_id,
	website_pageviews.pageview_url,
	COUNT(DISTINCT website_pageviews.website_session_id) AS sessions,
	COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_pageviews.website_session_id) AS viewed_product_to_order_rate
FROM website_pageviews
	LEFT JOIN orders
		ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at BETWEEN '2013-02-01' AND '2013-03-01'
	AND website_pageviews.pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
GROUP BY 1;

-- Assignment Product-Level Website Pathing
-- Step 1: Select relevent /product pageviews with website_session_id
CREATE TEMPORARY TABLE products_pageviews
SELECT
	website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_Product_2'
        ELSE 'check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at <'2013-04-06'
	AND created_at > '2012-10-06'
    AND pageview_url = '/products';
    
SELECT * FROM products_pageviews;

-- Step 2: find the next pageview id that occurs AFTER the product pageview
CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT
	products_pageviews.time_period,
    products_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = products_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
GROUP BY 1,2;

-- Step 3: find the pageview_url associated with any applicable next pageview id
CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT
	sessions_w_next_pageview_id.time_period,
    sessions_w_next_pageview_id.website_session_id,
    website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = sessions_w_next_pageview_id.min_next_pageview_id;

-- Step 4: summarize the data and analyze the pre vs post periods
SELECT
	time_period,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
	COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) to_lovebear,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY time_period;

-- Assignment - Building Product Conversion Funnels
-- Step 1: select all pageviews for relevant sessions
CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT
	website_session_id,
    website_pageview_id,
    pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at < '2013-04-10'
	AND created_at > '2013-01-06'
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');

-- Step 2: figure out which pageview urls to look for
SELECT DISTINCT
	website_pageviews.pageview_url
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;

-- Step 3: pull all pageviews and identify the funnel steps
SELECT
	sessions_seeing_product_pages.website_session_id,
    sessions_seeing_product_pages.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY
	sessions_seeing_product_pages.website_session_id,
    website_pageviews.created_at;

-- Step 4: create session-level conversion funnel view
CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check logic'
	END AS product_seen,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
SELECT
	sessions_seeing_product_pages.website_session_id,
    sessions_seeing_product_pages.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY
	sessions_seeing_product_pages.website_session_id,
    website_pageviews.created_at
) AS pageview_level
GROUP BY
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check logic'
	END;

-- Step 5: aggregate the data to assess funnel performance
-- Final output part 1: aggregating funnels
SELECT
	product_seen,
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;

-- Final output part 2: converting to click rates
SELECT
	product_seen,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_page_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_product_level_made_it_flags
GROUP BY product_seen; 