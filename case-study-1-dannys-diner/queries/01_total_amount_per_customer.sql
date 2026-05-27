-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    SUM(m.price) AS total_sales
FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY 1;

-- Output:
-- customer_id | total_sales
-- A           | 76
-- B           | 74
-- C           | 36

-- Insight:
-- Customers A and B have similar spending patterns (~$75),
-- while C spent half as much, suggesting different engagement levels.
