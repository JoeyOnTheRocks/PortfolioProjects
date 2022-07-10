USE mavenfuzzyfactory;
-- Analyzing Refund Rates
-- Example
SELECT
	order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd AS price_paid_usd,
    order_items.created_at,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at
FROM order_items
	LEFT JOIN order_item_refunds
		ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.order_id IN(3489,32049,27061);

-- Assignment - Analyzing Refund Rates
SELECT
	YEAR(order_items.created_at) AS yr,
    MONTH(order_items.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_refund_rt,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_item_refunds.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_refund_rt,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_refund_rt,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_refund_rt
FROM order_items
	LEFT JOIN order_item_refunds
		ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;