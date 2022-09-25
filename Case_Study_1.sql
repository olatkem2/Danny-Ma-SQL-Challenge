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
GROUP BY sa.customer_id 

-- 2. Answer

SELECT customer_id
FROM dbo.sales 