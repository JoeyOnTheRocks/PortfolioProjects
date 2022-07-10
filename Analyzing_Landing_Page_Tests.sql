-- Assignment - Analyzing Landing Page Tests
USE mavenfuzzyfactory;

-- Find when new page /lander launched
SELECT
	MIN(created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews 
WHERE pageview_url = '/lander-1'
	AND created_at IS NOT NULL;
-- first_created_at = '2012-06-19 00:35:54'
-- first_pageview_id = 23504

-- Find first website_pageview_id for relevant sessions
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_sessions.created_at < '2012-07-28'
        AND website_pageviews.website_pageview_id > 23504
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id;
    
-- Bring landing page to each session, restricting to home or lander-1
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_page
SELECT 
	first_test_pageviews.website_session_id,
	website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

-- QA Query
-- SELECT * FROM nonbrand_test_sessions_w_landing_page;

-- Table to have count of pageviews per session, limiting to bounced_sessions
CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT
	nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_sessions_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_sessions_w_landing_page
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
GROUP BY
	nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_sessions_w_landing_page.landing_page
HAVING
	COUNT(website_pageviews.website_pageview_id) = 1;
    
-- QA Query
-- SELECT * FROM nonbrand_test_bounced_sessions;

-- Previewing query
SELECT
	nonbrand_test_sessions_w_landing_page.landing_page,
    nonbrand_test_sessions_w_landing_page.website_session_id,
    nonbrand_test_bounced_sessions.website_session_id AS bounced_website_session_id
FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
		ON nonbrand_test_sessions_w_landing_page.website_session_id = nonbrand_test_bounced_sessions.website_session_id
ORDER BY
	nonbrand_test_sessions_w_landing_page.website_session_id;

-- Final output comparing home to lander-1
SELECT
	nonbrand_test_sessions_w_landing_page.landing_page,
    COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id)/COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS bounce_rate
FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
		ON nonbrand_test_sessions_w_landing_page.website_session_id = nonbrand_test_bounced_sessions.website_session_id
GROUP BY
	nonbrand_test_sessions_w_landing_page.landing_page;