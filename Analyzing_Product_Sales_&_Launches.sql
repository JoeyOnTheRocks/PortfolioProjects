USE mavenfuzzyfactory;
-- Analyzing Product Sales & Launches
-- Exmaple Query
SELECT
	COUNT(order_id) AS orders,
	SUM(price_usd) AS revenue,
	SUM(price_usd-cogs_usd) AS margin,
	AVG(price_usd) AS average_order_value
FROM orders
WHERE order_id BETWEEN 100 AND 200;

-- Demo
SELECT
	primary_product_id,
	COUNT(order_id) AS orders,
    SUM(price_usd) AS revenue,
    SUM(price_usd - cogs_usd) AS margin,
    AVG(price_usd) AS aov
FROM orders
WHERE order_id BETWEEN 10000 AND 11000 -- arbitrary for demo
GROUP BY 1
ORDER BY 2 DESC;

-- Assignment - Product Level Sales Analysis
SELECT
	YEAR(created_at) as yr,
    MONTH(created_at) as mo,
    COUNT(DISTINCT order_id) as number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1,2;

-- Assignment - Analyzing Product Launches
SELECT
	YEAR(website_sessions.created_at) as yr,
    MONTH(website_sessions.created_at) as mo,
    COUNT(DISTINCT orders.order_id) as orders,
	COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN orders.primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN orders.primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 1,2;