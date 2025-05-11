--Task 1
--Create a query for analyzing the annual sales data for the years 1999 
--to 2001, focusing on different sales channels and regions: 'Americas,' 
--'Asia,' and 'Europe.' 
--The resulting report should contain the following columns:
--AMOUNT_SOLD: This column should show the total sales amount for each 
--sales channel
--% BY CHANNELS: In this column, we should display the percentage of 
--total sales for each channel (e.g. 100% - total sales for Americas in 
--1999, 63.64% - percentage of sales for the channel “Direct Sales”)
--% PREVIOUS PERIOD: This column should display the same percentage 
--values as in the '% BY CHANNELS' column but for the previous year
--% DIFF: This column should show the difference between the 
--'% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the 
--change in sales percentage from the previous year.
--The final result should be sorted in ascending order based on 
--three criteria: first by 'country_region,' then by 'calendar_year,' 
--and finally by 'channel_desc'

WITH sales_data AS (
  SELECT
    t.calendar_year,
    co.country_region,  
    ch.channel_desc,
    SUM(s.amount_sold) AS amount_sold
  FROM sales s
  JOIN times t ON s.time_id = t.time_id
  JOIN channels ch ON s.channel_id = ch.channel_id
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN countries co ON c.country_id = co.country_id
  WHERE t.calendar_year BETWEEN 1999 AND 2001
  GROUP BY t.calendar_year, co.country_region, ch.channel_desc
),
total_sales_per_year AS (
  SELECT
    t.calendar_year,
    co.country_region,  -- Promenjeno u country_region
    SUM(s.amount_sold) AS total_sales
  FROM sales s
  JOIN times t ON s.time_id = t.time_id
  JOIN customers c ON s.cust_id = c.cust_id
  JOIN countries co ON c.country_id = co.country_id
  WHERE t.calendar_year BETWEEN 1999 AND 2001
  GROUP BY t.calendar_year, co.country_region
),
sales_percentage AS (
  SELECT
    sd.calendar_year,
    sd.country_region,
    sd.channel_desc,
    sd.amount_sold,
    ts.total_sales,
    (sd.amount_sold / ts.total_sales) * 100 AS percent_by_channels
  FROM sales_data sd
  JOIN total_sales_per_year ts
    ON sd.calendar_year = ts.calendar_year
    AND sd.country_region = ts.country_region
),
previous_year_sales AS (
  SELECT
    sd.calendar_year + 1 AS calendar_year,
    sd.country_region,
    sd.channel_desc,
    sd.percent_by_channels AS percent_previous_period
  FROM sales_percentage sd
  WHERE sd.calendar_year < 2001
)
SELECT
  sp.calendar_year,
  sp.country_region,
  sp.channel_desc,
  sp.amount_sold,
  CONCAT(ROUND(sp.percent_by_channels, 2), '%') AS "% BY CHANNELS",  -- Dodajemo simbol '%'
  CONCAT(ROUND(COALESCE(pys.percent_previous_period, 0), 2), '%') AS "% PREVIOUS PERIOD",  -- Dodajemo simbol '%'
  CONCAT(ROUND(sp.percent_by_channels - COALESCE(pys.percent_previous_period, 0), 2), '%') AS "% DIFF"  -- Dodajemo simbol '%'
FROM sales_percentage sp
LEFT JOIN previous_year_sales pys
  ON sp.calendar_year = pys.calendar_year
  AND sp.country_region = pys.country_region
  AND sp.channel_desc = pys.channel_desc
ORDER BY sp.country_region, sp.calendar_year, sp.channel_desc;

--You need to create a query that meets the following requirements:
--Generate a sales report for the 49th, 50th, and 51st weeks 
--of 1999.
--Include a column named CUM_SUM to display the amounts 
--accumulated during each week.
--Include a column named CENTERED_3_DAY_AVG to show the 
--average sales for the previous, current, and following 
--days using a centered moving average.
--For Monday, calculate the average sales based on the 
--weekend sales (Saturday and Sunday) as well as Monday 
--and Tuesday.
--For Friday, calculate the average sales on Thursday, 
--Friday, and the weekend.
--Ensure that your calculations are accurate for 
--the beginning of week 49 and the end of week 51.



CREATE MATERIALIZED VIEW mv_sales_agg_1999_w49_51 AS
SELECT 
    s.time_id,
    t.calendar_week_number,
    t.calendar_year,
    t.day_number_in_week,
    t.day_name,
    s.amount_sold,
    SUM(s.amount_sold) OVER (
        PARTITION BY t.calendar_year, t.calendar_week_number
        ORDER BY t.day_number_in_week
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sum,
    LAG(s.amount_sold, 2) OVER w AS prev2,
    LAG(s.amount_sold, 1) OVER w AS prev_day,
    LEAD(s.amount_sold, 1) OVER w AS next_day,
    LEAD(s.amount_sold, 2) OVER w AS next2
FROM sales s
JOIN times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999 
  AND t.calendar_week_number BETWEEN 49 AND 51
WINDOW w AS (
    PARTITION BY t.calendar_year, t.calendar_week_number 
    ORDER BY t.day_number_in_week
);

SELECT 
    calendar_week_number,
    day_name,
    amount_sold,
    cum_sum,
    ROUND(
        CASE
            WHEN day_name = 'Monday' THEN (
                COALESCE(prev2, 0) + COALESCE(prev_day, 0) + amount_sold + COALESCE(next_day, 0)
            ) / (
                1 +
                CASE WHEN prev2 IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN prev_day IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN next_day IS NOT NULL THEN 1 ELSE 0 END
            )
            WHEN day_name = 'Friday' THEN (
                COALESCE(prev_day, 0) + amount_sold + COALESCE(next_day, 0) + COALESCE(next2, 0)
            ) / (
                1 +
                CASE WHEN prev_day IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN next_day IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN next2 IS NOT NULL THEN 1 ELSE 0 END
            )
            ELSE (
                COALESCE(prev_day, 0) + amount_sold + COALESCE(next_day, 0)
            ) / (
                1 +
                CASE WHEN prev_day IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN next_day IS NOT NULL THEN 1 ELSE 0 END
            )
        END,
    2) AS centered_3_day_avg
FROM mv_sales_agg_1999_w49_51
ORDER BY calendar_week_number, day_name;

--Task 3
--Please provide 3 instances of utilizing 
--window functions that include a frame clause, 
--using RANGE, ROWS, and GROUPS modes. 
--Additionally, explain the reason for 
--choosing a specific frame type for each example. 
--This can be presented as a single query or 
--as three distinct queries.

SELECT 
    cust_id,
    time_id,
    amount_sold,
    AVG(amount_sold) OVER (
        PARTITION BY cust_id
        ORDER BY time_id
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS moving_avg_amount
FROM sales
ORDER BY cust_id, time_id;

--Why ROWS?
--This is useful when i want to calculate 
--a moving average using the exact previous 
--and next row (in terms of time) for each customer, 
--regardless of their sales value. 
--It's typically used for sliding window averages, 
--such as for the last 3 sales.

SELECT 
    s.cust_id,
    t.calendar_year,
    t.day_name,
    t.time_id,
    s.amount_sold,
    SUM(s.amount_sold) OVER (
        PARTITION BY s.cust_id
        ORDER BY t.time_id
        RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
    ) AS total_last_7_days
FROM sales s
JOIN times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999;

--Why RANGE?
--This is ideal when i'm working with time-based 
--calculations and want to sum values within 
--a specific time range (like the last 7 days). 
--It doesn't depend on the number of rows but on 
--the value of time intervals, 
--which is useful for running totals over specific periods.

SELECT 
    p.prod_id,
    p.prod_category,
    p.prod_list_price,
    RANK() OVER w AS price_rank,
    SUM(p.prod_list_price) OVER (
        w
        GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS sum_adjacent_price_groups
FROM products p
WINDOW w AS (
    PARTITION BY p.prod_category
    ORDER BY p.prod_list_price
)
ORDER BY p.prod_category, p.prod_list_price;

--Why GROUPS?
--GROUPS is used when i want to calculate 
--a frame that includes grouped values 
--(like products with the same price). 
--It ensures that entire groups before and after 
--the current row are included in the calculation, 
--which avoids breaking groups like ROWS would.
