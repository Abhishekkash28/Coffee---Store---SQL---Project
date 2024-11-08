  /* Coffee Store - Data Analysis */

-- coffee data 
select * from city;
select * from customers;
select *from products;
select * from sales;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000,2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;


-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


-- This query to check the total revenue.
select sum(total)as total_revenue
from sales
where  sale_date between '2023-10-01' and '2023-12-31';

-- In this query we are getting total revenue by city.
select ci.city_name,
	sum(s.total) as total_revenue
from sales s join customers c on s.customer_id = c.customer_id
join city ci on c.city_id =ci.city_id
where  sale_date between '2023-10-01' and '2023-12-31'
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select 
      p.product_name,
      count(s.sales_id) as total_orders
from sales s join products p 
on s.product_id =p.product_id
group by p.product_name
order by total_orders desc;


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customer,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_customer
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;


--  Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

with city_table as
(
SELECT 
	city_name ,
   ROUND(
	(population * 0.25)/1000000,2) as coffee_consumers
    from 
city
),
  customer_table
  as  
(
select ci.city_name,
    COUNT(DISTINCT s.customer_id) AS total_customer
 from sales s join customers c on s.customer_id = c.customer_id
join city ci on c.city_id =ci.city_id
group by ci.city_name
)
SELECT 
	customer_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customer_table.total_customer
FROM city_table
JOIN 
customer_table
ON city_table.city_name = customer_table.city_name;


-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?


SELECT * 
FROM 
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sales_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sales_id) DESC) as rank_no
	from sales s join products p on s.product_id=p.product_id
    join customers cu on s.customer_id = cu.customer_id
    join city ci on cu.city_id = ci.city_id
	GROUP BY ci.city_name,p.product_name

) as t1
WHERE rank_no <=3;


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?


SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customer
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY ci.city_name;


--  Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer


WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cust,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cust
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cust,
    ct.avg_sale_pr_cust,
    ROUND(cr.estimated_rent / ct.total_cust, 2) AS avg_rent_per_cust
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY avg_rent_per_cust DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, month, year
    ORDER BY ci.city_name, year, month
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND((cr_month_sale - last_month_sale) / last_month_sale * 100, 2) AS growth_ratio
FROM growth_ratio
WHERE 
    last_month_sale IS NOT NULL;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cust,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cust
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
    ORDER BY total_revenue DESC
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cust,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cust,
    ROUND(cr.estimated_rent / ct.total_cust, 2) AS avg_rent_per_cust
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;

/*
-- Recomendation
City 1: Pune
	1.The average rent per customer is notably low.
    2.The total revenue reached its highest level.
    3.The average sales per customer are significantly high.

City 2: Delhi
	1.The estimated number of coffee consumers is at its peak, reaching 7.7 million.
	2.The total number of customers is at a maximum, totaling 68.
    3.The average rent per customer stands at 330, remaining below 500.

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
    
    */
    
