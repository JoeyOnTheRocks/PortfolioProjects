USE mavenfuzzyfactory;
-- Analyzing Direct Traffic
SELECT 
    CASE
		WHEN http_referer IS NULL THEN 'direct type in'
		WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
        ELSE 'other'
	END AS channel_group,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary range
	-- AND utm_source IS NULL
GROUP BY 1
ORDER BY 2 DESC;

-- Volume of direct traffic and other paid traffic

-- Assignment - Analyzing Direct Traffic
SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
    COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic,
    COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM website_sessions
WHERE
	created_at < '2012-12-23'
GROUP BY
	YEAR(created_at),
    MONTH(created_at);
    
-- Assignment alternative solution
SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM (
SELECT
	website_session_id,
    created_at,
	CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group
FROM website_sessions
WHERE
	created_at < '2012-12-23'
) AS sessions_w_channel_group
GROUP BY
	YEAR(created_at),
    MONTH(created_at);