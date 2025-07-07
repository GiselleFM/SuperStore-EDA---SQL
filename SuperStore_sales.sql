-- Business Sales Analysis – Superstore Dataset
-- SQL Documentation with Explanations and Insights

-- Set the database to be used
USE SuperStore;

-- 1. Yearly Sales Overview
-- Calculates total sales and number of unique customers per year
SELECT 
  DATETRUNC(YEAR, order_date) AS order_year,
  SUM(Sales) AS total_sales,
  COUNT(DISTINCT customer_id) AS total_customers
FROM sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR, order_date)
ORDER BY order_year;

-- 2. Monthly Sales Overview
-- Shows monthly trends in sales and customer acquisition
SELECT 
  DATETRUNC(MONTH, order_date) AS order_month,
  SUM(Sales) AS total_sales,
  COUNT(DISTINCT customer_id) AS total_customers
FROM sales
WHERE order_date IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

-- 3. Cumulative Sales by Year
-- Demonstrates growth by calculating running total per year
SELECT 
  order_date,
  total_sales,
  SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales
FROM (
  SELECT 
    DATETRUNC(YEAR, order_date) AS order_date,
    SUM(Sales) AS total_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY DATETRUNC(YEAR, order_date)
) t;

-- 4. Cumulative Monthly Sales per Year
-- Tracks monthly cumulative performance within each year
SELECT 
  order_date,
  total_sales,
  SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales
FROM (
  SELECT 
    DATETRUNC(MONTH, order_date) AS order_date,
    SUM(Sales) AS total_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY DATETRUNC(MONTH, order_date)
) t;

-- 5. Performance by Category
-- Compares each category's sales to its average and to the previous year
WITH yearly_category_sales AS (
  SELECT
    DATETRUNC(YEAR, order_date) AS order_year,
    Category,
    SUM(sales) AS current_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY category, DATETRUNC(YEAR, order_date)
)
SELECT
  order_year,
  category,
  current_sales,
  AVG(current_sales) OVER (PARTITION BY category) AS average_sales,
  current_sales - AVG(current_sales) OVER (PARTITION BY category) AS diff_avg,
  CASE 
    WHEN current_sales > AVG(current_sales) OVER (PARTITION BY category) THEN 'Above Average'
    WHEN current_sales < AVG(current_sales) OVER (PARTITION BY category) THEN 'Under Average'
    ELSE 'Same as Average'
  END AS avg_change,
  LAG(current_sales) OVER (PARTITION BY category ORDER BY order_year) AS previous_year_sales,
  current_sales - LAG(current_sales) OVER (PARTITION BY category ORDER BY order_year) AS diff_py,
  CASE 
    WHEN current_sales > LAG(current_sales) OVER (PARTITION BY category ORDER BY order_year) THEN 'Increase'
    WHEN current_sales < LAG(current_sales) OVER (PARTITION BY category ORDER BY order_year) THEN 'Decrease'
    ELSE 'No Change'
  END AS py_change
FROM yearly_category_sales
ORDER BY category, order_year;

-- 6. Sales Distribution by State
-- Calculates each state's share of total sales
WITH state_sales AS (
  SELECT 
    State,
    SUM(Sales) AS total_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY state
)
SELECT 
  State,
  total_sales,
  SUM(total_sales) OVER () AS total_sales_general,
  CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM state_sales
ORDER BY total_sales DESC;

-- 7. Sales Distribution by Category
WITH category_sales AS (
  SELECT 
    category,
    SUM(Sales) AS total_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY category
)
SELECT 
  category,
  total_sales,
  SUM(total_sales) OVER () AS total_sales_general,
  CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- 8. Sales Distribution by Region
WITH region_sales AS (
  SELECT 
    Region,
    SUM(Sales) AS total_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY region
)
SELECT 
  region,
  total_sales,
  SUM(total_sales) OVER () AS total_sales_general,
  CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM region_sales
ORDER BY total_sales DESC;

-- 9. Sales Distribution by Sub-category
WITH sub_sales AS (
  SELECT 
    sub_Category,
    SUM(Sales) AS total_sales
  FROM sales
  WHERE order_date IS NOT NULL
  GROUP BY sub_category
)
SELECT 
  sub_category,
  total_sales,
  SUM(total_sales) OVER () AS total_sales_general,
  CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM sub_sales
ORDER BY total_sales DESC;

-- 10. Product Segmentation by Sales Range
-- Groups products based on their total sales into defined revenue brackets
WITH sales_segment AS (
  SELECT 
    Product_id,
    product_name,
    SUM(sales) AS total_sales,
    CASE 
      WHEN SUM(sales) > 1000000 THEN '+1M'
      WHEN SUM(sales) BETWEEN 500000 AND 1000000 THEN '+500K'
      WHEN SUM(sales) BETWEEN 100000 AND 500000 THEN '+100K'
      ELSE 'Below'
    END AS sales_range
  FROM sales
  GROUP BY product_name, product_id
)
SELECT
  sales_range,
  COUNT(product_id) AS total_products
FROM sales_segment
GROUP BY sales_range
ORDER BY total_products DESC;

-- 11. Customer Segmentation
-- Segments customers into VIP, Regular, or New based on total spend and customer lifespan
WITH customer_spent AS (
  SELECT 
    customer_id,
    SUM(sales) AS total_spent,
    MIN(order_date) AS first_order,
    MAX(order_Date) AS last_order,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
  FROM sales
  GROUP BY customer_id
)
SELECT
  customer_segment,
  COUNT(customer_id) AS total_clients
FROM (
  SELECT 
    customer_id,
    total_spent,
    lifespan,
    CASE 
      WHEN total_spent >= 5000000 AND lifespan >= 12 THEN 'VIP'
      WHEN total_spent >= 1000000 AND lifespan >= 12 THEN 'Regular'
      ELSE 'New'
    END AS customer_segment
  FROM customer_spent
) t
GROUP BY customer_segment;
