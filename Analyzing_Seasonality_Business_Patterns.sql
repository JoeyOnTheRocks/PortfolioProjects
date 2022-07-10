USE mavenfuzzyfactory;
-- Analyzing Seasonality & Business Patterns Demo
SELECT
	website_session_id,
    creted_at,
    HOUR(created_at) AS hr,
    WEEKDAY(created_at) AS wkday, -- 0 = Mon, 1 = Tues, etc
    CASE
		WHEN DAYOFWEEK(created_at) = 0 THEN 'Monday'
        WHEN DAYOFWEEK(created_at) = 1 THEN 'Tuesday'
        ELSE 'other_day'
	END AS clean_weekday,
    QUARTER(created_at) AS qtr,
    MONTH(created_at) AS mo,
    DATE(created_at) AS date,
    WEEK(created_at) AS wk
FROM website_sessions
WHERE website_session_id BETWEEN 150000 AND 155000; -- arbirtrary for demo

-- Assignment - Analyzing Seasonality
-- Sessions by month
SELECT
	YEAR(website_sessions.created_at) as yr,
    MONTH(website_sessions.created_at) as mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE
	website_sessions.created_at < '2013-01-01'
GROUP BY 1,2;

-- Sessions by week
SELECT
	MIN(DATE(website_sessions.created_at)) AS week_start_date,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE
	website_sessions.created_at < '2013-01-01'
GROUP BY
	YEARWEEK(website_sessions.created_at);
    
-- Assignment - Analyzing Business Patterns
SELECT
	hr,
    ROUND(AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END)) AS mon,
    ROUND(AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END)) AS tue,
    ROUND(AVG(CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END)) AS wed,
    ROUND(AVG(CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END)) AS thu,
    ROUND(AVG(CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END)) AS fri,
    ROUND(AVG(CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END)) AS sat,
    ROUND(AVG(CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END)) AS sun
FROM (
SELECT
	DATE(created_at) AS created_date,
    WEEKDAY(created_at) AS wkday,
    HOUR(created_at) AS hr,
    COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2013-09-15' AND '2013-11-15'
GROUP BY 1,2,3
) daily_hourly_sessions
GROUP BY 1
ORDER BY 1;