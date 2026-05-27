-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    SUM(m.price) AS total_sales
FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY 1;

-- Insight:
-- Customers A and B have similar spending (~$75 each), while C 
-- spent less than half ($36). For a loyalty program, A and B are 
-- the priority retention targets while C represents an upsell 
-- opportunity.

-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id,
    COUNT(DISTINCT order_date) AS count_of_different_days
FROM sales GROUP BY 1;

-- Insight:
-- Customer B is the most frequent visitor (6 different days), 
-- followed by A (4 days) and C (2 days). Visit frequency and 
-- total spend tell different stories — A spends almost the same 
-- as B but in fewer visits, suggesting larger per-visit baskets.

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT customer_id, product_name
FROM(
SELECT
	s.customer_id, m.product_name,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rnk
FROM sales s JOIN menu m ON s.product_id = m.product_id) AS A
WHERE rnk = 1;

-- Insight:
-- Customers A and B both have multiple "first items" because they 
-- ordered different products on their first visit day. Ramen 
-- appears as a popular first choice for customer C — possibly 
-- relevant for a "welcome offer" promotion targeting new customers.

-- Design decision:
-- Used RANK() instead of ROW_NUMBER() to preserve ties honestly 
-- rather than arbitrarily picking one product when a customer 
-- bought multiple items on the same day.

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- easy way first:
SELECT 
	m.product_name,
    COUNT(s.product_id) AS count_sold_product
FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY 1 ORDER BY count_sold_product DESC LIMIT 1;
-- tryhard way to do it (it can handle ties tho)
SELECT 
	product_name, 
    count_sold_product
FROM(
SELECT 
	m.product_name,
    COUNT(s.product_id) AS count_sold_product,
	RANK() OVER (ORDER BY COUNT(s.product_id) DESC) AS rnk
FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY 1) AS A
WHERE rnk = 1;

-- Insight:
-- Ramen is the clear bestseller (8 purchases), nearly double the 
-- next product. It's the strongest candidate for promotional 
-- bundling, loyalty multipliers, or stock prioritization.

-- 5. Which item was the most popular for each customer?
SELECT
	customer_id,
    product_name,
    product_count
FROM(
SELECT
	s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS product_count,
    RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(s.product_id) DESC) AS rnk
FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY 1,2) AS A
WHERE rnk = 1;

-- Insight:
-- Customer A's and C's favorite is ramen, but customer B shows a 
-- three-way tie (curry, sushi, ramen — 2 each). B has the most 
-- diverse palate; targeting them with new menu items or variety 
-- bundles likely yields better engagement than single-item promotions.

-- 6. Which item was purchased first by the customer after they became a member?
SELECT
	customer_id, join_date, order_date, product_id, product_name
FROM(
SELECT 
	s.customer_id,
    me.join_date,
    s.order_date,
    s.product_id,
    m.product_name,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as rnk
FROM sales s JOIN members me ON s.customer_id = me.customer_id JOIN menu m ON m.product_id = s.product_id
WHERE s.order_date > me.join_date) AS A
WHERE rnk = 1;

-- Insight:
-- Customer A's first purchases after joining occurred on the same 
-- day as their join_date (2021-01-07, ordering curry). Customer B 
-- waited until 2021-01-11 (sushi). The membership signup → first 
-- purchase window is a meaningful conversion metric worth tracking.


-- 7. Which item was purchased just before the customer became a member?
-- ROW NUMBER CAN BE USED INSTEAD OF RANK TO FORCE ONLY ONE RESULT
SELECT
	customer_id, join_date, order_date, product_id, product_name
FROM(
SELECT 
	s.customer_id,
    me.join_date,
    s.order_date,
    s.product_id,
    m.product_name,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as rnk
FROM sales s JOIN members me ON s.customer_id = me.customer_id JOIN menu m ON m.product_id = s.product_id
WHERE s.order_date < me.join_date) AS A
WHERE rnk = 1;

-- Insight:
-- Customer A purchased sushi AND curry on the same day before 
-- joining (2021-01-01). Customer B's last pre-membership purchase 
-- was sushi (2021-01-04). These pre-membership preferences could 
-- inform personalized "welcome" offers when customers sign up.

-- Design decision:
-- Used RANK() instead of ROW_NUMBER() to preserve the tie for 
-- customer A. Arbitrarily picking one of the two products would 
-- hide real information from the analysis.

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id,
	COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_amount
FROM sales s JOIN members me ON s.customer_id = me.customer_id JOIN menu m ON m.product_id = s.product_id
WHERE s.order_date < me.join_date GROUP BY 1;

-- Insight:
-- Customer A purchased 2 items totaling $25 before joining, while 
-- B purchased 3 items totaling $40. Both became members after 
-- demonstrating consistent interest — a useful signal that 
-- non-members with repeat purchases are strong conversion candidates.

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	s.customer_id,
    SUM(CASE 
			WHEN s.product_id = 1 THEN 20*m.price 
			ELSE 10*m.price
			END) 
		AS points
FROM sales s JOIN menu m ON m.product_id = s.product_id GROUP BY 1 ORDER BY s.customer_id ASC;

-- Insight:
-- Customer B leads in points (940), followed by A (860) and C (360). 
-- B's lead comes partly from their sushi purchases (which carry the 
-- 2x multiplier). The current points system rewards sushi buyers 
-- disproportionately — worth reviewing if this aligns with the 
-- intended customer behavior.

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
SELECT
	s.customer_id,
    SUM(CASE 
			WHEN s.order_date < me.join_date THEN 0
			WHEN (s.order_date <= DATE_ADD(me.join_date, INTERVAL 6 DAY) OR 
				 (s.product_id = 1 AND s.order_date > DATE_ADD(me.join_date, INTERVAL 6 DAY))) THEN 20*m.price 
			ELSE 10*m.price
			END) 
		AS points
FROM sales s JOIN menu m ON m.product_id = s.product_id JOIN members me ON me.customer_id = s.customer_id
WHERE s.order_date <= "2021-01-31"
GROUP BY 1 
ORDER BY s.customer_id ASC;

-- Insight:
-- At the end of January, customer A accumulated 1,370 points and B 
-- accumulated 820. The first-week 2x multiplier significantly boosts 
-- early engagement — A in particular benefited because they made 
-- multiple purchases during their first member week. This promotion 
-- structure successfully drives behavior in the critical onboarding 
-- window.
