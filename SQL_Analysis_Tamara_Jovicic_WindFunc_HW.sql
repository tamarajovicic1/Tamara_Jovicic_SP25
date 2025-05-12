--Task 1. Create a query to produce a sales report highlighting the top customers with 
--the highest sales across different sales channels. 
--This report should list the top 5 customers for each channel. 
--Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' 
--which represents the percentage of a customer's sales relative to the total sales within 
--their respective channel.
--Please format the columns as follows:
--Display the total sales amount with two decimal places
--Display the sales percentage with four decimal places and include the percent sign (%) at the end
--Display the result for each channel in descending order of sales

--Calculated total sales amount per customer per sales channel
WITH sales_by_customer_channel AS (
    -- Calculated total sales per customer and channel
    SELECT 
        s.cust_id,
        cu.cust_first_name,
        cu.cust_last_name,
        c.channel_desc,
        ROUND(SUM(s.amount_sold), 2) AS total_sales
    FROM sales s
    JOIN customers cu ON s.cust_id = cu.cust_id
    JOIN channels c ON s.channel_id = c.channel_id
    GROUP BY s.cust_id, cu.cust_first_name, cu.cust_last_name, c.channel_desc
),

-- Calculated total sales per sales channel
channel_totals AS (
    SELECT 
        c.channel_desc,
        SUM(s.amount_sold) AS channel_total_sales
    FROM sales s
    JOIN channels c ON s.channel_id = c.channel_id
    GROUP BY c.channel_desc
),

-- Added a calculated sales percentage per customer within their respective channel
sales_with_percentage AS (
    SELECT 
        scc.cust_id,
        scc.cust_first_name,
        scc.cust_last_name,
        scc.channel_desc,
        scc.total_sales,
        -- Calculated percentage of total sales for the customer within the channel
        ROUND((scc.total_sales / ct.channel_total_sales) * 100, 4) AS sales_pct
    FROM sales_by_customer_channel scc
    JOIN channel_totals ct ON scc.channel_desc = ct.channel_desc
),

-- Ranked customers by their total sales in the same channel
ranked AS (
    SELECT 
        a.*,
        COUNT(*) AS rank_in_channel
    FROM sales_with_percentage a
    JOIN sales_with_percentage b
      ON a.channel_desc = b.channel_desc
     AND a.total_sales <= b.total_sales
    GROUP BY 
        a.cust_id, a.cust_first_name, a.cust_last_name, a.channel_desc, a.total_sales, a.sales_pct
)

-- Selected only the top 5 customers per channel and formatted the columns
SELECT 
    channel_desc,
    cust_last_name,
    cust_first_name,
    TO_CHAR(total_sales, 'FM99999990.00') AS amount_sold,
    TO_CHAR(sales_pct, 'FM999990.0000') || '%' AS sales_percentage
FROM ranked
WHERE rank_in_channel <= 5
ORDER BY channel_desc, total_sales DESC;


--Create a query to retrieve data for a report that displays the total sales for all 
--products in the Photo category in the Asian region for the year 2000. 
--Calculate the overall report total and name it 'YEAR_SUM'
--Display the sales amount with two decimal places
--Display the result in descending order of 'YEAR_SUM'
--For this report, consider exploring the use of the crosstab function. 
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Quarterly pivot report for the 'Photo' category in the 'Asia' region for the year 2000
SELECT 
  prod_name,
  COALESCE(q1, 0) AS q1,
  COALESCE(q2, 0) AS q2,
  COALESCE(q3, 0) AS q3,
  COALESCE(q4, 0) AS q4,
  -- Calculate the total annual sales (year_sum) by summing all quarters
  ROUND(COALESCE(q1, 0) + COALESCE(q2, 0) + COALESCE(q3, 0) + COALESCE(q4, 0), 2) AS year_sum
FROM crosstab(
  $$
  -- Get sales per product and classify months into quarters
  SELECT 
    p.prod_name,
    CASE 
      WHEN t.calendar_month_number BETWEEN 1 AND 3 THEN 'q1'
      WHEN t.calendar_month_number BETWEEN 4 AND 6 THEN 'q2'
      WHEN t.calendar_month_number BETWEEN 7 AND 9 THEN 'q3'
      WHEN t.calendar_month_number BETWEEN 10 AND 12 THEN 'q4'
    END AS quarter,
    ROUND(SUM(s.amount_sold)::numeric, 2) AS quarterly_sum
  FROM sh.sales s
  INNER JOIN sh.products p ON s.prod_id = p.prod_id
  INNER JOIN sh.customers c ON s.cust_id = c.cust_id
  INNER JOIN sh.countries ctr ON c.country_id = ctr.country_id
  INNER JOIN sh.times t ON s.time_id = t.time_id
  -- Filter by product category, region, and year
  WHERE p.prod_category = 'Photo'
    AND ctr.country_subregion = 'Asia'
    AND t.calendar_year = 2000
  GROUP BY p.prod_name, quarter
  ORDER BY p.prod_name, quarter
  $$,
  -- Define the expected quarters to ensure correct pivoting
  $$ VALUES ('q1'), ('q2'), ('q3'), ('q4') $$
) AS pivot (
  prod_name text,
  q1 numeric,
  q2 numeric,
  q3 numeric,
  q4 numeric
)
-- Sort the results by total yearly sales in descending order
ORDER BY year_sum DESC;


--Create a query to generate a sales report for customers ranked in the top 300 based on 
--total sales in the years 1998, 1999, and 2001. 
--The report should be categorized based on sales channels, and separate calculations 
--should be performed for each channel.
--Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
--Categorize the customers based on their sales channels
--Perform separate calculations for each sales channel
--Include in the report only purchases made on the channel specified
--Format the column so that total sales are displayed with two decimal places

-- Generate a report of top 300 customers by total sales per year and channel (for 1998, 1999, and 2001)

--Filter sales for the years of interest and join with time info
WITH sales_with_year AS (
  -- Filter sales for the years 1998, 1999, and 2001 only
  SELECT 
    s.cust_id,
    s.channel_id,
    s.amount_sold,
    t.calendar_year
  FROM sh.sales s
  INNER JOIN sh.times t ON s.time_id = t.time_id
  WHERE t.calendar_year IN (1998, 1999, 2001)
),

customer_sales AS (
  -- Calculate total sales per customer, channel, and year
  SELECT 
    swy.cust_id,
    swy.channel_id,
    swy.calendar_year,
    SUM(swy.amount_sold) AS total_sales
  FROM sales_with_year swy
  GROUP BY swy.cust_id, swy.channel_id, swy.calendar_year
),

ranked_sales AS (
  -- Rank customers by total sales within each channel and year
  SELECT 
    cs.*,
    RANK() OVER (PARTITION BY cs.channel_id, cs.calendar_year ORDER BY cs.total_sales DESC) AS sales_rank
  FROM customer_sales cs
),

top_per_year AS (
  -- Keep only the top 300 customers per channel and year
  SELECT *
  FROM ranked_sales
  WHERE sales_rank <= 300
),

qualified_customers AS (
  -- Customers who were in the top 300 for all three years within the same channel
  SELECT cust_id, channel_id
  FROM top_per_year
  GROUP BY cust_id, channel_id
  HAVING COUNT(DISTINCT calendar_year) = 3
)

-- Final result: total sales for those qualified customers, grouped by channel
SELECT 
  ch.channel_desc,
  cu.cust_id,
  cu.cust_last_name,
  cu.cust_first_name,
  ROUND(SUM(tp.total_sales)::numeric, 2) AS amount_sold
FROM top_per_year tp
INNER JOIN qualified_customers qc ON tp.cust_id = qc.cust_id AND tp.channel_id = qc.channel_id
INNER JOIN sh.customers cu ON tp.cust_id = cu.cust_id
INNER JOIN sh.channels ch ON tp.channel_id = ch.channel_id
GROUP BY ch.channel_desc, cu.cust_id, cu.cust_last_name, cu.cust_first_name
ORDER BY ch.channel_desc, amount_sold DESC;


--Create a query to generate a sales report for January 2000, February 2000, and 
--March 2000 specifically for the Europe and Americas regions.
--Display the result by months and by product category in alphabetical order.

SELECT *
FROM crosstab(
  $$
  SELECT 
    t.calendar_month_desc,
    p.prod_category,
    ctr.country_region,
    ROUND(SUM(s.amount_sold)::numeric, 2) AS total_sales
  FROM sh.sales s
  INNER JOIN sh.products p ON s.prod_id = p.prod_id
  INNER JOIN sh.times t ON s.time_id = t.time_id
  INNER JOIN sh.customers c ON s.cust_id = c.cust_id
  INNER JOIN sh.countries ctr ON c.country_id = ctr.country_id
  WHERE t.calendar_year = 2000
    AND t.calendar_month_number IN (1, 2, 3)
    AND ctr.country_region IN ('Europe', 'Americas')
  GROUP BY t.calendar_month_desc, p.prod_category, ctr.country_region
  ORDER BY t.calendar_month_desc, p.prod_category
  $$,
  $$ VALUES ('Americas'), ('Europe') $$
) AS pivot_table (
  calendar_month_desc text,
  prod_category text,
  "Americas Sales" numeric,
  "Europe Sales" numeric
)
ORDER BY calendar_month_desc, prod_category;
