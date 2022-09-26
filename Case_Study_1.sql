/* -----------------------------------------
    CASE STUDY TABLES, QUESTIONS AND ANSWERS
   ----------------------------------------- */

/* Tables
1. members
2. menu
3. sales */

/* Case Study Questions
Each of the following case study questions can be answered using a single SQL statement:

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
  how many points do customer A and B have at the end of January?  */

--- 1. Answer

SELECT sa.customer_id, SUM(me.price) AS total_amount
FROM  dbo.sales AS sa
LEFT OUTER JOIN dbo.menu AS me
ON sa.product_id = me.product_id
GROUP BY sa.customer_id;

-- 2. Answer

SELECT customer_id, COUNT(DISTINCT order_date) AS no_of_days
FROM dbo.sales 
GROUP BY customer_id;

-- 3. Answer

WITH temp AS 
    (
    SELECT se.customer_id, me.product_name, se.order_date,
    RANK() OVER(PARTITION BY se.customer_id ORDER BY se.order_date) as rank
    FROM dbo.sales as se
    LEFT JOIN dbo.menu AS me
    ON se.product_id = me.product_id
    )

SELECT t.customer_id, t.product_name
FROM temp AS t
WHERE rank = 1;

-- 4. Answer

SELECT  TOP 1 me.product_name, COUNT(se.product_id) AS no_of_purchased_items
FROM dbo.sales as se
LEFT JOIN dbo.menu AS me
ON se.product_id = me.product_id
GROUP BY me.product_name
ORDER BY no_of_purchased_items DESC;

-- 5. Answer

WITH temp AS 
    (
    SELECT se.customer_id, me.product_name, COUNT(se.product_id) AS no_of_purchased_items,
            RANK() OVER(PARTITION BY se.customer_id ORDER BY COUNT(se.product_id) DESC) AS rank
    FROM dbo.sales as se
    LEFT JOIN dbo.menu AS me
    ON se.product_id = me.product_id
    GROUP BY se.customer_id, me.product_name
    )

SELECT t.customer_id, t.product_name, t.no_of_purchased_items, t.rank
FROM temp AS t
WHERE rank=1
ORDER BY t.customer_id ASC, t.no_of_purchased_items DESC;

-- 6. Answer

WITH temp AS 
    (
    SELECT se.customer_id, me.product_name, se.order_date, m.join_date,
    RANK() OVER(PARTITION BY se.customer_id ORDER BY se.order_date) as rank
    FROM dbo.sales as se
    LEFT JOIN dbo.menu AS me
    ON se.product_id = me.product_id
    LEFT JOIN dbo.members AS m
    ON se.customer_id = m.customer_id
    WHERE se.order_date > m.join_date
    )

SELECT t.customer_id, t.product_name -- t.order_date, t.join_date, t.rank
FROM temp AS t
WHERE rank = 1;

-- 7. Answer





