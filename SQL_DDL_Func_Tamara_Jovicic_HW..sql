-- task 1. Create a view
-- Create a view called 'sales_revenue_by_category_qtr' 
-- that shows the film category and total sales revenue for the current quarter and year. 
-- The view should only display categories with at least one sale in the current quarter. 
-- Note: when the next quarter begins, it will be considered as the current quarter.

CREATE OR REPLACE VIEW SALES_REVENUE_BY_CATEGORY_QTR AS
SELECT 
    C.NAME AS CATEGORY_NAME,
    SUM(P.AMOUNT) AS TOTAL_SALES_REVENUE
FROM 
    PAYMENT P
JOIN 
    RENTAL R ON P.RENTAL_ID = R.RENTAL_ID
JOIN 
    INVENTORY I ON R.INVENTORY_ID = I.INVENTORY_ID
JOIN 
    FILM F ON I.FILM_ID = F.FILM_ID
JOIN 
    FILM_CATEGORY FC ON F.FILM_ID = FC.FILM_ID
JOIN 
    CATEGORY C ON FC.CATEGORY_ID = C.CATEGORY_ID
WHERE 
    EXTRACT(QUARTER FROM P.PAYMENT_DATE) = EXTRACT(QUARTER FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM P.PAYMENT_DATE) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    C.NAME
HAVING 
    SUM(P.AMOUNT) > 0;



-- task 2. Create a query language functions
-- Create a query language function called 'get_sales_revenue_by_category_qtr' 
-- that accepts one parameter representing the current quarter and year 
-- and returns the same result as the 'sales_revenue_by_category_qtr' view.

CREATE OR REPLACE FUNCTION GET_SALES_REVENUE_BY_CATEGORY_QTR(CURRENT_QUARTER INT, CURRENT_YEAR INT)
RETURNS TABLE(CATEGORY_NAME TEXT, TOTAL_SALES_REVENUE NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        C.NAME AS CATEGORY_NAME,
        SUM(P.AMOUNT) AS TOTAL_SALES_REVENUE
    FROM 
        PAYMENT P
    JOIN 
        RENTAL R ON P.RENTAL_ID = R.RENTAL_ID
    JOIN 
        INVENTORY I ON R.INVENTORY_ID = I.INVENTORY_ID
    JOIN 
        FILM F ON I.FILM_ID = F.FILM_ID
    JOIN 
        FILM_CATEGORY FC ON F.FILM_ID = FC.FILM_ID
    JOIN 
        CATEGORY C ON FC.CATEGORY_ID = C.CATEGORY_ID
    WHERE 
        EXTRACT(QUARTER FROM P.PAYMENT_DATE) = CURRENT_QUARTER 
        AND EXTRACT(YEAR FROM P.PAYMENT_DATE) = CURRENT_YEAR
    GROUP BY 
        C.NAME
    HAVING 
        SUM(P.AMOUNT) > 0;
END;
$$ LANGUAGE PLPGSQL;

-- task 3. Create procedure language functions
-- Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
-- The function should format the result set as follows:
-- Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);

CREATE OR REPLACE FUNCTION MOST_POPULAR_FILMS_BY_COUNTRIES(COUNTRIES TEXT[])
RETURNS TABLE(COUNTRY TEXT, FILM_ID INT, TITLE TEXT, RATING TEXT, LANGUAGE TEXT, LENGTH INT, RELEASE_YEAR INT, POPULARITY INT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CO.NAME AS COUNTRY,
        F.FILM_ID,
        F.TITLE,
        F.RATING,
        L.NAME AS LANGUAGE,
        F.LENGTH,
        F.RELEASE_YEAR,
        COUNT(*) AS POPULARITY
    FROM 
        PAYMENT P
    JOIN 
        RENTAL R ON P.RENTAL_ID = R.RENTAL_ID
    JOIN 
        INVENTORY I ON R.INVENTORY_ID = I.INVENTORY_ID
    JOIN 
        FILM F ON I.FILM_ID = F.FILM_ID
    JOIN 
        CUSTOMER CUST ON P.CUSTOMER_ID = CUST.CUSTOMER_ID
    JOIN 
        ADDRESS A ON CUST.ADDRESS_ID = A.ADDRESS_ID
    JOIN 
        CITY CT ON A.CITY_ID = CT.CITY_ID
    JOIN 
        COUNTRY CO ON CT.COUNTRY_ID = CO.COUNTRY_ID
    JOIN 
        LANGUAGE L ON F.LANGUAGE_ID = L.LANGUAGE_ID
    WHERE 
        CO.NAME = ANY(COUNTRIES)
    GROUP BY 
        CO.NAME, F.FILM_ID, F.TITLE, F.RATING, L.NAME, F.LENGTH, F.RELEASE_YEAR
    ORDER BY 
        POPULARITY DESC;
END;
$$ LANGUAGE PLPGSQL;


-- task 4. Create procedure language functions
-- Create a function that generates a list of movies available in stock 
-- based on a partial title match (e.g., movies containing the word 'love' in their title). 
-- The titles of these movies are formatted as '%...%', and if a movie with 
-- the specified title is not in stock, return a message indicating that it was not found.
-- The function should produce the result set in the following format 
-- (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
-- Query (example):select * from core.films_in_stock_by_title('%love%’);

CREATE OR REPLACE FUNCTION FILMS_IN_STOCK_BY_TITLE(PARTIAL_TITLE TEXT)
RETURNS TABLE(ROW_NUM INT, FILM_ID INT, TITLE TEXT, LANGUAGE TEXT, CUSTOMER_NAME TEXT, RENTAL_DATE DATE) AS $$
DECLARE
    MOVIE RECORD;
    ROW_NUMBER INT := 0;
BEGIN
    FOR MOVIE IN
        SELECT 
            F.FILM_ID,
            F.TITLE,
            L.NAME AS LANGUAGE,
            C.FIRST_NAME || ' ' || C.LAST_NAME AS CUSTOMER_NAME,
            R.RENTAL_DATE
        FROM 
            FILM F
        JOIN 
            INVENTORY I ON F.FILM_ID = I.FILM_ID
        JOIN 
            LANGUAGE L ON F.LANGUAGE_ID = L.LANGUAGE_ID
        LEFT JOIN 
            RENTAL R ON I.INVENTORY_ID = R.INVENTORY_ID
        LEFT JOIN 
            CUSTOMER C ON R.CUSTOMER_ID = C.CUSTOMER_ID
        WHERE 
            F.TITLE ILIKE PARTIAL_TITLE
            AND I.INVENTORY_ID NOT IN (
                SELECT INVENTORY_ID FROM RENTAL WHERE RETURN_DATE IS NULL
            )
    LOOP
        ROW_NUMBER := ROW_NUMBER + 1;
        ROW_NUM := ROW_NUMBER;
        RETURN NEXT MOVIE;
    END LOOP;

    IF ROW_NUMBER = 0 THEN
        RAISE EXCEPTION 'NO MOVIES FOUND MATCHING TITLE: %', PARTIAL_TITLE;
    END IF;
END;
$$ LANGUAGE PLPGSQL;
    

-- task 5. Create procedure language functions
-- Create a procedure language function called 'new_movie' that takes a movie title as a 
-- parameter and inserts a new movie with the given title in the film table. 
-- The function should generate a new unique film ID, set the rental rate to 4.99, 
-- the rental duration to three days, the replacement cost to 19.99. 
-- The release year and language are optional and by default should be current year 
-- and Klingon respectively. The function should also verify that 
-- the language exists in the 'language' table. 
-- Then, ensure that no such function has been created before; if so, replace it.

CREATE OR REPLACE FUNCTION NEW_MOVIE(MOVIE_TITLE TEXT, RELEASE_YEAR INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE), LANGUAGE TEXT DEFAULT 'KLINGON')
RETURNS VOID AS $$
DECLARE
    LANG_ID INT;
BEGIN
    SELECT LANGUAGE_ID INTO LANG_ID FROM LANGUAGE WHERE NAME = LANGUAGE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'LANGUAGE % DOES NOT EXIST', LANGUAGE;
    END IF;

    IF EXISTS (
        SELECT 1 FROM FILM WHERE TITLE = MOVIE_TITLE AND RELEASE_YEAR = RELEASE_YEAR
    ) THEN
        RAISE EXCEPTION 'MOVIE WITH THE TITLE % ALREADY EXISTS', MOVIE_TITLE;
    END IF;

    INSERT INTO FILM (TITLE, RENTAL_RATE, RENTAL_DURATION, REPLACEMENT_COST, RELEASE_YEAR, LANGUAGE_ID)
    VALUES (MOVIE_TITLE, 4.99, 3, 19.99, RELEASE_YEAR, LANG_ID);
END;
$$ LANGUAGE PLPGSQL;

