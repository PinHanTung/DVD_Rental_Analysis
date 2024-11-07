/*Q1. The average rental count for each movie in the family category.*/

-- Select the category_id for family movies
WITH t1 AS (
  SELECT category_id, name
  FROM category
  WHERE name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
),

-- Select family movies
t2 AS (
  SELECT t1.name, f2.title, f2.film_id
  FROM t1
  JOIN film_category f1 ON f1.category_id = t1.category_id
  JOIN film f2 ON f2.film_id = f1.film_id
),

-- Count the rentals of each family movies
t3 AS (
  SELECT
    t2.title film_title,
    t2.name category_name,
    COUNT(r.rental_id) rental_count
  FROM t2
  LEFT JOIN inventory i ON i.film_id = t2.film_id
  LEFT JOIN rental r ON r.inventory_id = i.inventory_id
  GROUP BY 1, 2
  ORDER BY 2, 1
)

--Calculate the average rental count for each family category
SELECT 
  category_name,
  ROUND(AVG(rental_count), 2) avg_retal_count
FROM t3
GROUP BY 1
ORDER BY 1;




/* Q2. Determine rental duration quartiles for all movies and display family category. */

-- Select the category_id for family movies
WITH t1 AS (
  SELECT category_id, name
  FROM category
  WHERE name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
),

-- Select family movies
t2 AS (
  SELECT t1.name, f2.title, f2.film_id
  FROM t1
  JOIN film_category f1 ON f1.category_id = t1.category_id
  JOIN film f2 ON f2.film_id = f1.film_id
),

-- Calculate the average rental days for all movies
t3 AS (
  SELECT
    f.film_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (return_date - rental_date)))/86400, 2) AS rental_duration
  FROM rental r
  JOIN inventory i ON i.inventory_id = r.inventory_id
  JOIN film f ON f.film_id = i.film_id
  GROUP BY 1
),

-- Calculate the quartiles based on t3
t4 AS (
  SELECT 
    t3.film_id,
    rental_duration,
    NTILE(4) OVER (ORDER BY rental_duration) AS quartile
  FROM t3
)

-- Select the family category and show the number of quartiles they contain
SELECT
  t2.name category,
  t4.quartile,
  COUNT(*)
FROM t2
JOIN t4 ON t4.film_id = t2.film_id
GROUP BY 1, 2
ORDER BY 1, 2;





/* Q3. Rental count comparison between both stores */

SELECT
  LEFT((DATE_TRUNC('month', r.rental_date) :: TEXT), 7) mon,
  s1.store_id,
  count(*) count_retails
FROM store s1
JOIN staff s2 ON s2.store_id = s1.store_id
JOIN rental r ON r.staff_id = s2.staff_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC;





/* Q4. Top 10 customers' payment difference in 2007 */

-- Identify the top 10 customers by total spending
WITH t1 AS (
  SELECT customer_id, SUM(amount)
  FROM payment
  GROUP BY 1
  ORDER BY 2 DESC
  LIMIT 10
),

-- Calculate the monthly total spending for each customer in t1
t2 AS (
  SELECT
    LEFT(DATE_TRUNC('month', payment_date) :: TEXT, 7) pay_mon,
    c.first_name||' '||c.last_name full_name,
    SUM(amount) pay_amount
  FROM payment p
  JOIN t1 ON t1.customer_id = p.customer_id
  JOIN customer c ON c.customer_id = p.customer_id
  GROUP BY 1, 2
  ORDER BY 2, 1
),

-- Calculate the monthly spending difference based on t2
t3 AS (
  SELECT 
    t2.pay_mon,
    t2.full_name,
    (t2.pay_amount - LAG(t2.pay_amount) OVER (PARTITION BY full_name ORDER BY t2.pay_mon)) AS difference
  FROM t2
)

-- Remove initial months with no difference
SELECT t3.*
FROM t3
WHERE difference IS NOT NULL
ORDER BY 1, 2;