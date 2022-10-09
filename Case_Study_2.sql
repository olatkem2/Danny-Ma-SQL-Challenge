/* -----------------------------------------
    CASE STUDY TABLES, QUESTIONS AND ANSWERS
   ----------------------------------------- */

/* Tables
1. runners
2. customer_orders
3. runner_orders
4. pizza_names
5. pizza_recipes
6. pizza_toppings */

/* Case Study Questions

A. Pizza Metrics

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

B. Runner and Customer Experience

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?

C. Ingredient Optimisation

1. What are the standard ingredients for each pizza?
2. What was the most commonly added extra?
3. What was the most common exclusion?
4. Generate an order item for each record in the customers_orders table in the format of one of the following:
   Meat Lovers
   Meat Lovers - Exclude Beef
   Meat Lovers - Extra Bacon
   Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the 
   customer_orders table and add a 2x in front of any relevant ingredients
   For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

D. Pricing and Ratings

1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
2. What if there was an additional $1 charge for any pizza extras?
   Add cheese is $1 extra
3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
    customer_id
    order_id
    runner_id
    rating
    order_time
    pickup_time
    Time between order and pickup
    Delivery duration
    Average speed
    Total number of pizzas
5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

E. Bonus Questions

1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu? */

SELECT * 
FROM
dbo.runners;
-- dbo.customer_orders;
-- dbo.runner_orders;
-- dbo.pizza_names;
-- dbo.pizza_recipes;
-- dbo.pizza_toppings;

-- A. Pizza Metrics 

-- 1. Answer

SELECT COUNT(pizza_id) AS no_of_pizza_ordered
FROM   dbo.customer_orders;

-- 2. Answer

/*  SELECT customer_id, COUNT(DISTINCT order_id) AS unique_orders
    FROM dbo.customer_orders -- This is calculate total unique orders per customer
    GROUP BY customer_id
    ORDER BY unique_orders DESC  */
SELECT COUNT(DISTINCT order_id) AS total_unique_orders
FROM dbo.customer_orders;

-- 3. Answer

WITH temp AS
    (SELECT runner_id, order_id, pickup_time, distance, duration, 
        CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation
    FROM dbo.runner_orders)

SELECT t.runner_id, COUNT(t.order_id) AS no_of_successful_orders
FROM temp AS t
WHERE cleansed_cancellation IS NULL
GROUP BY t.runner_id;

-- 4. Answer

SELECT pn.pizza_id, CAST(pn.pizza_name AS VARCHAR) AS pizza_type, COUNT(ro.order_id) AS no_of_delivered_pizzas
FROM 
    (SELECT runner_id, order_id, pickup_time, distance, duration, 
        CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation
    FROM dbo.runner_orders) AS ro
INNER JOIN dbo.customer_orders AS co
ON ro.order_id=co.order_id
INNER JOIN dbo.pizza_names AS pn
ON co.pizza_id=pn.pizza_id
WHERE ro.cleansed_cancellation IS NULL
GROUP BY pn.pizza_id, CAST(pn.pizza_name AS VARCHAR)   -- To cater for the TEXT field

-- 5. Answer

SELECT co.customer_id, CAST(pn.pizza_name AS VARCHAR) AS pizza_type, COUNT(co.order_id) AS no_of_ordered_pizza
FROM dbo.customer_orders AS co
INNER JOIN dbo.pizza_names AS pn
ON co.pizza_id=pn.pizza_id
GROUP BY co.customer_id, CAST(pn.pizza_name AS VARCHAR) -- To cater for the TEXT field
ORDER BY co.customer_id ASC;

--5. Alternative Answer

SELECT customer_id,
    COALESCE(SUM(CASE WHEN pizza_id=1 THEN 1 END),0) AS 'meat_lovers',
    COALESCE(SUM(CASE WHEN pizza_id=2 THEN 1 END),0) AS 'vegetarian' -- Still NOT clear but it worked!!!
FROM customer_orders
GROUP BY customer_id;

-- 6. Answer

SELECT TOP 1 co.order_id, COUNT(ro.order_id) AS no_of_delivered_pizzas
     FROM 
        (SELECT runner_id, order_id, pickup_time, distance, duration, 
            CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
                ELSE cancellation
            END AS cleansed_cancellation
        FROM dbo.runner_orders) AS ro
INNER JOIN dbo.customer_orders AS co
ON ro.order_id=co.order_id
WHERE ro.cleansed_cancellation IS NULL
GROUP BY co.order_id
ORDER BY no_of_delivered_pizzas DESC;

-- 7. Answer

WITH temp AS 

(SELECT co.customer_id, ro.order_id, co.cleansed_exclusions, co.cleansed_extras
  FROM 
        (SELECT runner_id, order_id, pickup_time, distance, duration, 
            CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
                ELSE cancellation
            END AS cleansed_cancellation
        FROM dbo.runner_orders) AS ro
  INNER JOIN 
    (SELECT order_id, customer_id, pizza_id, order_time,
            CASE exclusions
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE exclusions
            END AS cleansed_exclusions,
            CASE extras
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE extras
            END AS cleansed_extras
        FROM dbo.customer_orders) AS co
   ON ro.order_id=co.order_id
   WHERE cleansed_cancellation IS NULL)

SELECT t.customer_id,
    COUNT(CASE WHEN t.is_change=0 THEN 0 END) AS no_change,
    COUNT(CASE WHEN t.is_change=1 THEN 1 END) AS change
FROM 
    (SELECT t.*,
            CASE WHEN t.cleansed_exclusions IS NULL AND t.cleansed_extras IS NULL THEN 0 ELSE 1 END AS is_change
       FROM temp AS t) AS t
GROUP BY t.customer_id;

-- 8. Answer

WITH temp AS 

(SELECT co.customer_id, ro.order_id, co.cleansed_exclusions, co.cleansed_extras
  FROM 
        (SELECT runner_id, order_id, pickup_time, distance, duration, 
            CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
                ELSE cancellation
            END AS cleansed_cancellation
        FROM dbo.runner_orders) AS ro
  INNER JOIN 
    (SELECT order_id, customer_id, pizza_id, order_time,
            CASE exclusions
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE exclusions
            END AS cleansed_exclusions,
            CASE extras
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE extras
            END AS cleansed_extras
        FROM dbo.customer_orders) AS co
   ON ro.order_id=co.order_id
   WHERE cleansed_cancellation IS NULL)

SELECT t.customer_id, COUNT(*) AS order_with_both_modification
FROM temp AS t
WHERE (t.cleansed_exclusions IS NOT NULL) AND (t.cleansed_extras IS NOT NULL)
GROUP BY t.customer_id;

-- 9. Answer

SELECT 
--  DATENAME(DAY,co.order_time) AS order_day,
    DATENAME(HOUR, co.order_time) AS order_hour,
    COUNT(co.order_id) AS no_of_ordered_pizza
FROM dbo.customer_orders AS co
GROUP BY DATENAME(HOUR, co.order_time)
ORDER BY no_of_ordered_pizza DESC;

-- 10. Answer

SELECT 
    DATENAME(WEEKDAY,co.order_time) AS day_of_week_1,
    DATEPART(WEEKDAY,co.order_time) AS day_of_week_2,
--  DATENAME(HOUR, co.order_time) AS order_hour,
    COUNT(co.order_id) AS no_of_ordered_pizza
FROM dbo.customer_orders AS co
GROUP BY DATENAME(WEEKDAY,co.order_time), DATEPART(WEEKDAY,co.order_time)
ORDER BY no_of_ordered_pizza DESC;

-- B. Runner and Customer Experience

-- 1. Answer

SELECT CONCAT('Week ',DATEPART(WEEK, registration_date)) AS week,
       COUNT(*) AS no_of_runners
FROM dbo.runners
GROUP BY CONCAT('Week ',DATEPART(WEEK, registration_date))
ORDER BY no_of_runners DESC;

-- 2. Answer

WITH cleansed_runner_orders AS
    (
    SELECT C.* FROM (
    SELECT runner_id, order_id, distance, duration, 
        CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation,
        CASE pickup_time
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE TRY_CAST(pickup_time AS DATETIME)
        END AS cleansed_pickup_time
    FROM dbo.runner_orders) AS C
    WHERE cleansed_pickup_time IS NOT NULL
    ),
     customer_orders AS 
       (
       SELECT DISTINCT order_id, order_time
       FROM dbo.customer_orders
        ) 
SELECT ro.runner_id, AVG(DATEDIFF(MINUTE,co.order_time, ro.cleansed_pickup_time)) AS avg_pickup_min
FROM customer_orders AS co
INNER JOIN cleansed_runner_orders AS ro
ON ro.order_id=co.order_id
GROUP BY ro.runner_id

-- 3. Answer
-- There is a positive relationship between number of pizza and the average time it takes to prepare

WITH cleansed_runner_orders AS
    (
    SELECT C.* FROM (
    SELECT runner_id, order_id, distance, duration, 
        CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation,
        CASE pickup_time
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE TRY_CAST(pickup_time AS DATETIME)
        END AS cleansed_pickup_time
    FROM dbo.runner_orders) AS C
    WHERE cleansed_pickup_time IS NOT NULL
    ),
     customer_orders AS 
       (
       SELECT order_id, COUNT(*) AS no_of_pizza, order_time
       FROM dbo.customer_orders
       GROUP BY order_id, order_time
        ) 
SELECT co.no_of_pizza, 
        (AVG(DATEDIFF(MINUTE,co.order_time, ro.cleansed_pickup_time))*60) AS avg_pickup_sec
FROM  cleansed_runner_orders AS ro
INNER JOIN customer_orders AS co
ON ro.order_id=co.order_id
GROUP BY co.no_of_pizza;

-- 4. Answer

 WITH runner_order AS 
   (
    SELECT runner_id, order_id,
       CASE distance
            WHEN 'null' THEN NULL
       ELSE REPLACE(distance, 'km', '')
       END AS cleansed_distance,
       CASE cancellation 
                WHEN '' THEN NULL 
                WHEN 'null' THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation
    FROM dbo.runner_orders
   ),
     customer_order AS
   (
    SELECT customer_id, order_id
    FROM dbo.customer_orders
   )
SELECT co.customer_id, (ROUND(AVG(CAST(ro.cleansed_distance AS FLOAT)), 1)) AS avg_distance
FROM runner_order AS ro
INNER JOIN customer_order AS co
ON ro.order_id=co.order_id
WHERE ro.cleansed_cancellation IS NULL
GROUP BY co.customer_id; 

-- 5. Answer

 WITH runner_order AS 
   (
    SELECT runner_id, order_id,
        CASE
                WHEN distance IN ('', 'null') THEN NULL
            ELSE REPLACE(distance, 'km', '')
        END AS cleansed_distance,
        CASE 
                WHEN cancellation IN ('','null') THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation,
        CASE
                WHEN pickup_time IN ('','null') THEN NULL
                ELSE TRY_CAST(pickup_time AS DATETIME)
        END AS cleansed_pickup_time,
        CASE
                WHEN duration IN ('null','') THEN NULL
                WHEN duration LIKE '%_minute' THEN REPLACE(duration, 'minute', '')
                WHEN duration LIKE '%_mins' THEN REPLACE(duration, 'mins', '')
            ELSE REPLACE(duration, 'minutes', '')  
        END AS cleansed_duration
    FROM dbo.runner_orders
   )
SELECT longest_dur, shortest_dur, 
        (longest_dur-shortest_dur) AS diff_btw_longest_shortest_dur
FROM 
    (SELECT MAX(CAST(cleansed_duration AS INT)) AS longest_dur, MIN(CAST(cleansed_duration AS INT)) AS shortest_dur
     FROM runner_order) AS x;

-- 6. Answer

 WITH runner_order AS 
   (
    SELECT runner_id, order_id,
        CASE
                WHEN distance IN ('', 'null') THEN NULL
            ELSE REPLACE(distance, 'km', '')
        END AS cleansed_distance,
        CASE 
                WHEN cancellation IN ('','null') THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation,
        CASE
                WHEN pickup_time IN ('','null') THEN NULL
                ELSE TRY_CAST(pickup_time AS DATETIME)
        END AS cleansed_pickup_time,
        CASE
                WHEN duration IN ('null','') THEN NULL
                WHEN duration LIKE '%_minute' THEN REPLACE(duration, 'minute', '')
                WHEN duration LIKE '%_mins' THEN REPLACE(duration, 'mins', '')
            ELSE REPLACE(duration, 'minutes', '')  
        END AS cleansed_duration
    FROM dbo.runner_orders
   )
SELECT runner_id, order_id, 
        ROUND(CAST(cleansed_distance AS FLOAT)/(CAST(cleansed_duration AS INT)/60.0),1) AS speed_kmph
FROM runner_order AS r
WHERE cleansed_duration IS NOT NULL
ORDER BY runner_id, order_id;

-- 7. Answer

 WITH runner_order AS 
   (
    SELECT runner_id, order_id,
        CASE
                WHEN distance IN ('', 'null') THEN NULL
            ELSE REPLACE(distance, 'km', '')
        END AS cleansed_distance,
        CASE 
                WHEN cancellation IN ('','null') THEN NULL
            ELSE cancellation
        END AS cleansed_cancellation,
        CASE
                WHEN pickup_time IN ('','null') THEN NULL
                ELSE TRY_CAST(pickup_time AS DATETIME)
        END AS cleansed_pickup_time,
        CASE
                WHEN duration IN ('null','') THEN NULL
                WHEN duration LIKE '%_minute' THEN REPLACE(duration, 'minute', '')
                WHEN duration LIKE '%_mins' THEN REPLACE(duration, 'mins', '')
            ELSE REPLACE(duration, 'minutes', '')  
        END AS cleansed_duration
    FROM dbo.runner_orders
   )

SELECT runner_id, is_successful, is_not_successful,
        CAST(is_successful AS FLOAT)/CAST(total_del AS FLOAT)*100 AS percent_successful
FROM
        (SELECT runner_id,
                COUNT(CASE WHEN cleansed_cancellation IS NULL THEN 1 END) AS is_successful,
                COUNT(CASE WHEN cleansed_cancellation IS NOT NULL THEN 1 END) AS is_not_successful,
                COUNT(*) AS total_del
        FROM runner_order
        GROUP BY runner_id) AS x
GROUP BY runner_id, is_successful, is_not_successful, total_del;

-- C. Ingredient Optimisation

-- 1. Answer

WITH pizzanames_toppings AS

  (SELECT pr.pizza_id, pn.pizza_name, TRY_CAST(REPLACE(value,' ','') AS INT) AS toppings
    FROM dbo.pizza_names AS pn
    INNER JOIN  dbo.pizza_recipes AS pr
    ON pn.pizza_id=pr.pizza_id
    CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS NVARCHAR), ','))
    -- You can do this with a combo of STRING_TO_ARRAY and UNNEST(work just like STRING_SPLIT) in PostgreSQL

SELECT pz.pizza_id, pz.pizza_name, pz.toppings, pt.topping_name
FROM pizzanames_toppings AS pz
INNER JOIN pizza_toppings AS pt
ON pt.topping_id=pz.toppings;

-- 1. Alternate

WITH pizzanames_toppings AS

  (SELECT pr.pizza_id, pn.pizza_name, TRY_CAST(REPLACE(value,' ','') AS INT) AS toppings
    FROM dbo.pizza_names AS pn
    INNER JOIN  dbo.pizza_recipes AS pr
    ON pn.pizza_id=pr.pizza_id
    CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS NVARCHAR), ','))

SELECT pz.pizza_id,
    STRING_AGG(CAST(pt.topping_name AS NVARCHAR),',') AS topping_name
FROM pizzanames_toppings AS pz
INNER JOIN pizza_toppings AS pt
ON pt.topping_id=pz.toppings
GROUP BY pz.pizza_id;

-- 2. Answer

WITH customer_order AS 
   (
        SELECT order_id, customer_id, pizza_id, order_time, 
            CASE exclusions
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE exclusions
            END AS cleansed_exclusions,
            CASE extras
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE extras
            END AS cleansed_extras
        FROM dbo.customer_orders      
   ),
    unnested_extra AS
    (
        SELECT pizza_id, cleansed_extras, REPLACE(value,' ','') AS unested_extra
        FROM customer_order
        CROSS APPLY STRING_SPLIT(CAST(cleansed_extras AS NVARCHAR), ',')
   )

SELECT TOP 1 ue.unested_extra, CAST(pt.topping_name AS NVARCHAR) AS topping_name, 
            COUNT(ue.unested_extra) AS no_of_extras
FROM unnested_extra AS ue
INNER JOIN dbo.pizza_toppings AS pt
ON ue.unested_extra=pt.topping_id
GROUP BY ue.unested_extra, CAST(pt.topping_name AS NVARCHAR)
ORDER BY no_of_extras DESC;

-- 3. Answer

WITH customer_order AS 
   (
        SELECT order_id, customer_id, pizza_id, order_time, 
            CASE exclusions
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE exclusions
            END AS cleansed_exclusions,
            CASE extras
                WHEN '' THEN NULL
                WHEN 'null' THEN NULL
                ELSE extras
            END AS cleansed_extras
        FROM dbo.customer_orders      
   ),
    unnested_exclusions AS
    (
        SELECT pizza_id, cleansed_exclusions, REPLACE(value,' ','') AS unested_exclusions
        FROM customer_order
        CROSS APPLY STRING_SPLIT(CAST(cleansed_exclusions AS NVARCHAR), ',')
   )

SELECT  TOP 1 ue.unested_exclusions, CAST(pt.topping_name AS NVARCHAR) AS topping_name, 
            COUNT(ue.unested_exclusions) AS no_of_exclusions
FROM unnested_exclusions AS ue
INNER JOIN dbo.pizza_toppings AS pt
ON ue.unested_exclusions=pt.topping_id
GROUP BY ue.unested_exclusions, CAST(pt.topping_name AS NVARCHAR)
ORDER BY no_of_exclusions DESC;

-- 4. Answer: No solution yet, but the code snippet below is a proposed solution from Resagratia 

/* WITH orders AS (
  SELECT *, ROW_NUMBER() OVER () AS row_index
  FROM pizza_runner.customer_orders
),
exclusions AS (
  SELECT order_id, pizza_id, row_index, topping_name
  FROM (
    SELECT * FROM (
    	SELECT order_id, pizza_id, row_index,
        UNNEST(STRING_TO_ARRAY(exclusions, ', ')) AS exclusions
        FROM orders
    ) AS tmp
    WHERE exclusions NOT IN ('null' ,'')
  ) AS temp_table
  LEFT JOIN pizza_runner.pizza_toppings p
  ON temp_table.exclusions::INTEGER = p.topping_id
  
),
extras AS (
  SELECT order_id, pizza_id, row_index, topping_name
  FROM (
    SELECT * FROM (
    	SELECT order_id, pizza_id, row_index,
        UNNEST(STRING_TO_ARRAY(extras, ', ')) AS extras
        FROM orders
    ) AS tmp
    WHERE extras NOT IN ('null', '')
  ) AS temp_table
  LEFT JOIN pizza_runner.pizza_toppings p
  ON temp_table.extras::INTEGER = p.topping_id
  
),
exclusions_toppings AS (
  SELECT row_index, 
  STRING_AGG(topping_name, ', ') AS exclusions 
  FROM exclusions
  GROUP BY 1
),
extras_toppings AS (
  SELECT row_index, 
  STRING_AGG(topping_name, ', ') AS extras 
  FROM extras
  GROUP BY 1
)
SELECT CONCAT(pizza_name, 
              CASE WHEN t.exclusions IS NULL THEN '' ELSE ' - Exclude ' END, 
              t.exclusions,
             CASE WHEN e.extras IS NULL THEN '' ELSE ' - Exclude ' END,
              e.extras
             ) AS pizza_ordered 
FROM orders o
LEFT JOIN exclusions_toppings t USING (row_index)
LEFT JOIN extras_toppings e USING (row_index)
LEFT JOIN pizza_runner.pizza_names p USING (pizza_id); */

-- 5. Answer






























