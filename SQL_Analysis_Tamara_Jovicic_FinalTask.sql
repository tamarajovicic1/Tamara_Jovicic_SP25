--Create a query to generate a report that identifies for 
--each channel and throughout the entire period, 
--the regions with the highest quantity of products sold 
--(quantity_sold). 
--The resulting report should include the following columns:
--CHANNEL_DESC, COUNTRY_REGION
--SALES: This column will display the number 
--of products sold (quantity_sold) with two decimal places.
--SALES %: This column will show the percentage 
--of maximum sales in the region 
--(as displayed in the SALES column) 
--compared to the total sales for that channel. 
--The sales percentage should be displayed with 
--two decimal places and include the percent sign (%) at the end.
--Display the result in descending order of SALES

--Select final columns to display in the report
SELECT 
    ch.CHANNEL_DESC,                                      
    ranked.COUNTRY_REGION,                                
    --Region with the highest quantity sold in the channel
    ROUND(ranked.REGION_SALES, 2) AS SALES,               
    --Total quantity sold in that region (rounded to 2 decimals)
    CONCAT(ROUND(100.0 * ranked.REGION_SALES / ranked.TOTAL_CHANNEL_SALES, 2), '%') AS "SALES %"  
    --Percentage of this region's sales compared to total channel sales
FROM (
    SELECT 
        s.CHANNEL_ID,                                     
        --ID of the sales channel
        ctry.COUNTRY_REGION,                              
        --Region where the customer is located
        SUM(s.QUANTITY_SOLD) AS REGION_SALES,             
        --Total quantity sold in that region for this channel
        SUM(SUM(s.QUANTITY_SOLD)) OVER (PARTITION BY s.CHANNEL_ID) AS TOTAL_CHANNEL_SALES,
        --Total sales for the entire channel (used for % calculation)
        RANK() OVER (
            PARTITION BY s.CHANNEL_ID                     
            ORDER BY SUM(s.QUANTITY_SOLD) DESC            
            --Rank regions by total quantity sold (descending)
        ) AS SALES_RANK                                   
        --Rank to identify top region per channel
    FROM 
        sh.sales s                                        
        --Main sales data
    JOIN 
        sh.customers cust ON s.CUST_ID = cust.CUST_ID     
        --Link each sale to the customer
    JOIN 
        sh.countries ctry ON cust.COUNTRY_ID = ctry.COUNTRY_ID
        --Get the country/region for each customer
    GROUP BY 
        s.CHANNEL_ID, ctry.COUNTRY_REGION                 
        --Group sales by channel and region
) ranked
--Join with channels table to get the channel description
JOIN 
    sh.channels ch ON ranked.CHANNEL_ID = ch.CHANNEL_ID

--Only include the top region (rank = 1) per channel
WHERE 
    ranked.SALES_RANK = 1

--Order final result by quantity sold in descending order
ORDER BY 
    SALES DESC;


--Identify the subcategories of products with consistently 
--higher sales from 1998 to 2001 compared to the previous year. 
--Determine the sales for each subcategory from 1998 to 2001.
--Calculate the sales for the previous year for each subcategory.
--Identify subcategories where the sales from 
--1998 to 2001 are consistently higher than the previous year.
--Generate a dataset with a single column containing the identified prod_subcategory values.


--Final output: product subcategories with consistent year-over-year sales increase from 1998 to 2001
SELECT 
    PROD_SUBCATEGORY
FROM (
    --Get yearly sales per subcategory from 1997 to 2001
    SELECT 
        p.PROD_SUBCATEGORY,
        t.CALENDAR_YEAR,
        SUM(s.QUANTITY_SOLD) AS YEARLY_SALES,
        LAG(SUM(s.QUANTITY_SOLD)) OVER (
            PARTITION BY p.PROD_SUBCATEGORY 
            ORDER BY t.CALENDAR_YEAR
        ) AS PREV_YEAR_SALES
    FROM 
        sh.sales s
    JOIN 
        sh.products p ON s.PROD_ID = p.PROD_ID
    JOIN 
        sh.times t ON s.TIME_ID = t.TIME_ID
    WHERE 
        t.CALENDAR_YEAR BETWEEN 1997 AND 2001  
        --include 1997 to have data to compare 1998 against
    GROUP BY 
        p.PROD_SUBCATEGORY, t.CALENDAR_YEAR
) yearly_data
--Only focus on years 1998-2001, and compare with previous year
WHERE 
    CALENDAR_YEAR BETWEEN 1998 AND 2001
    AND YEARLY_SALES > PREV_YEAR_SALES   
    --keep only rows where current year sales > previous year

--Ensure each subcategory appears in all 4 years (1998–2001) with increasing trend
GROUP BY 
    PROD_SUBCATEGORY
HAVING 
    COUNT(*) = 4  
    --must have passed the condition for all 4 years
;

--Create a query to generate a sales report for 
--the years 1999 and 2000, focusing on quarters and 
--product categories. In the report you have to 
-- analyze the sales of products from the categories 
--'Electronics,' 'Hardware,' and 'Software/Other,' 
--across the distribution channels 'Partners' and 'Internet'.
--The resulting report should include the following columns:
--CALENDAR_YEAR: The calendar year
--CALENDAR_QUARTER_DESC: The quarter of the year
--PROD_CATEGORY: The product category
--SALES$: The sum of sales (amount_sold) for the product 
--category and quarter with two decimal places
--DIFF_PERCENT: Indicates the percentage by which sales 
--increased or decreased compared to the first quarter 
--of the year. For the first quarter, the column value is 'N/A.'
--The percentage should be displayed with two decimal places 
--and include the percent sign (%) at the end.
--CUM_SUM$: The cumulative sum of sales by quarters
--with two decimal places
--The final result should be sorted in ascending order based on two criteria: first by 'calendar_year,' then by 'calendar_quarter_desc'; and finally by 'sales' descending

SELECT 
    t.CALENDAR_YEAR,
    t.CALENDAR_QUARTER_DESC,
    p.PROD_CATEGORY,
    ROUND(SUM(s.AMOUNT_SOLD), 2) AS "SALES$",

    --Use quarter number to check if it's Q1, show 'N/A' if so
    CASE 
        WHEN t.CALENDAR_QUARTER_NUMBER = 1 THEN 'N/A'
        ELSE CONCAT(
            ROUND(
                100.0 * (SUM(s.AMOUNT_SOLD) - 
                         FIRST_VALUE(SUM(s.AMOUNT_SOLD)) OVER (
                             PARTITION BY t.CALENDAR_YEAR, p.PROD_CATEGORY 
                             ORDER BY t.CALENDAR_QUARTER_NUMBER
                         )
                ) / 
                FIRST_VALUE(SUM(s.AMOUNT_SOLD)) OVER (
                    PARTITION BY t.CALENDAR_YEAR, p.PROD_CATEGORY 
                    ORDER BY t.CALENDAR_QUARTER_NUMBER
                ),
            2),
        '%')
    END AS DIFF_PERCENT,

    --Cumulative sales per year/category
    ROUND(
        SUM(SUM(s.AMOUNT_SOLD)) OVER (
            PARTITION BY t.CALENDAR_YEAR, p.PROD_CATEGORY
            ORDER BY t.CALENDAR_QUARTER_NUMBER
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2
    ) AS "CUM_SUM$"

FROM 
    sh.sales s
JOIN 
    sh.products p ON s.PROD_ID = p.PROD_ID
JOIN 
    sh.times t ON s.TIME_ID = t.TIME_ID
JOIN 
    sh.channels c ON s.CHANNEL_ID = c.CHANNEL_ID

WHERE 
    t.CALENDAR_YEAR IN (1999, 2000)
    AND p.PROD_CATEGORY IN ('Electronics', 'Hardware', 'Software/Other')
    AND c.CHANNEL_DESC IN ('Partners', 'Internet')

GROUP BY 
    t.CALENDAR_YEAR,
    t.CALENDAR_QUARTER_DESC,
    t.CALENDAR_QUARTER_NUMBER,
    p.PROD_CATEGORY

ORDER BY 
    t.CALENDAR_YEAR ASC,
    t.CALENDAR_QUARTER_DESC ASC,
    "SALES$" DESC;





