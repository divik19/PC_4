USE gdb023;

SELECT 
    COUNT(*)
FROM
    dim_customer;

SELECT 
    COUNT(*)
FROM
    dim_product;

SELECT 
    COUNT(*)
FROM
    fact_gross_price;

SELECT 
    COUNT(*)
FROM
    fact_manufacturing_cost;

SELECT 
    COUNT(*)
FROM
    fact_pre_invoice_deductions;

SELECT 
    COUNT(*)
FROM
    fact_sales_monthly;

SELECT 
    *
FROM
    dim_customer
LIMIT 20;
SELECT 
    *
FROM
    dim_product
LIMIT 20;
SELECT 
    *
FROM
    fact_gross_price
LIMIT 20;
SELECT 
    *
FROM
    fact_manufacturing_cost
LIMIT 5;
SELECT 
    *
FROM
    fact_pre_invoice_deductions
LIMIT 20;
SELECT 
    *
FROM
    fact_sales_monthly
LIMIT 20;


-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
AND region = 'APAC';
  
-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields, 
-- unique_products_2020 
-- unique_products_2021 
-- percentage_chg

WITH year_2020 AS (
	SELECT 
		COUNT(DISTINCT product_code) AS unique_products_2020
	FROM
		fact_gross_price
	WHERE
		fiscal_year = '2020'
),
year_2021 as (
	SELECT 
		COUNT(DISTINCT product_code) AS unique_products_2021
	FROM
		fact_gross_price
	WHERE
		fiscal_year = '2021'
)
SELECT 
    unique_products_2020,
    unique_products_2021,
    CONCAT(ROUND(100.0 * (unique_products_2021 - unique_products_2020) / unique_products_2020,
            2), " %") AS percentage_chg
FROM
    year_2020,
    year_2021;

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields, 
-- segment 
-- product_count

SELECT 
    segment, 
    COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference

with year_2020 as (
	SELECT 
		segment, 
        COUNT(DISTINCT product_code) AS product_count_2020
	FROM
		dim_product
	INNER JOIN
		fact_gross_price 
		USING (product_code)
	WHERE
		fiscal_year = 2020
	GROUP BY segment
),
year_2021 as (
	SELECT 
		segment, 
        COUNT(DISTINCT product_code) AS product_count_2021
	FROM
		dim_product
	INNER JOIN
		fact_gross_price 
        USING (product_code)
	WHERE
		fiscal_year = 2021
	GROUP BY segment
)
SELECT 
    *, 
    product_count_2021 - product_count_2020 AS difference
FROM
    year_2020
INNER JOIN
    year_2021 
	USING (segment)
ORDER BY difference DESC;

-- 5. Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost

SELECT 
    product_code, product, manufacturing_cost
FROM
    fact_manufacturing_cost
INNER JOIN
    dim_product 
	USING (product_code)
WHERE
    manufacturing_cost IN (
		SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost 
		UNION 
        SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost
            )
ORDER BY manufacturing_cost DESC;

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
-- for the fiscal year 2021 and in the Indian market. The final output contains these fields: 
-- customer_code 
-- customer 
-- average_discount_percentage

SELECT 
    customer_code,
    customer,
    AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM
    dim_customer
INNER JOIN
    fact_pre_invoice_deductions 
    USING (customer_code)
WHERE
    fiscal_year = 2021 
AND market = 'India'
GROUP BY customer_code , customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount

SELECT 
    DATE_FORMAT(date, '%M %Y') AS month,
    fcm.fiscal_year AS Year,
    ROUND(SUM(sold_quantity * gross_price), 2) AS Gross_sales_Amount
FROM
    fact_sales_monthly AS fcm
INNER JOIN
    dim_customer 
    USING (customer_code)
INNER JOIN
    fact_gross_price 
    USING (product_code)
WHERE
    customer = 'Atliq Exclusive'
GROUP BY month , year
ORDER BY year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity
-- Quarter 
-- total_sold_quantity

SELECT 
    MONTH(date) AS months,
    QUARTER(date) AS quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY quarters , months
ORDER BY months;

SELECT 
    QUARTER(date) AS quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY quarters
ORDER BY total_sold_quantity DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields: 
-- channel 
-- gross_sales_mln 
-- percentage

with gross_sales_2021 as (
	SELECT 
		channel,
		ROUND(SUM(sold_quantity * gross_price), 2) AS gross_sales
	FROM
		dim_customer
	INNER JOIN
		fact_sales_monthly AS fsm 
        USING (customer_code)
	INNER JOIN
		fact_gross_price AS fgp 
         ON fgp.product_code = fsm.product_code
		AND fsm.fiscal_year = fgp.fiscal_year
	WHERE
		fgp.fiscal_year = 2021
	GROUP BY channel
),
total_sales_2021 AS (
    SELECT 
        SUM(gross_sales) AS total_gross_sales
    FROM gross_sales_2021
)
SELECT 
    gs.channel,
    Concat(ROUND(gs.gross_sales / 1000000, 2)," M") AS gross_sales_mln, 
    Concat(ROUND((gs.gross_sales / ts.total_gross_sales) * 100, 2), " %") AS percentage
FROM 
    gross_sales_2021 as gs,
    total_sales_2021 as ts
ORDER BY 
    gross_sales_mln DESC;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields:
-- division 
-- product_code
-- product 
-- total_sold_quantity 
-- rank_order

WITH ranked AS (
    SELECT 
        division,
        product_code,
        product,
        SUM(sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY division 
					 ORDER BY SUM(sold_quantity) DESC) AS rank_order
    FROM 
		dim_product 
    INNER JOIN 
		fact_sales_monthly 
		USING (product_code)
    WHERE 
		fiscal_year = 2021
    GROUP BY division, product_code, product
)
SELECT 
   *
FROM ranked
WHERE rank_order < 4
ORDER BY division, rank_order;

