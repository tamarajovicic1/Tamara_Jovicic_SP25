-- task 1. Create a view
-- Create a view called 'sales_revenue_by_category_qtr' 
-- that shows the film category and total sales revenue for the current quarter and year. 
-- The view should only display categories with at least one sale in the current quarter. 
-- Note: when the next quarter begins, it will be considered as the current quarter.
-- I'm sorry for missunderstanding! Hope this works 

CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
SELECT 
    c.name AS category_name,
    SUM(p.amount) AS total_sales_revenue
FROM 
    public.payment p
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE 
    EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE) AND
    EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    c.name
HAVING 
    SUM(p.amount) > 0;



-- task 2. Create a query language functions
-- Create a query language function called 'get_sales_revenue_by_category_qtr' 
-- that accepts one parameter representing the current quarter and year 
-- and returns the same result as the 'sales_revenue_by_category_qtr' view.

CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(current_quarter INT, current_year INT)
RETURNS TABLE(category_name TEXT, total_sales_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name AS category_name,
        SUM(p.amount) AS total_sales_revenue
    FROM 
        public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE 
        EXTRACT(QUARTER FROM p.payment_date) = current_quarter AND
        EXTRACT(YEAR FROM p.payment_date) = current_year
    GROUP BY 
        c.name
    HAVING 
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;


-- task 3. Create procedure language functions
-- Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
-- The function should format the result set as follows:
-- Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);

CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE(country TEXT, film_id INT, title TEXT, rating TEXT, language TEXT, length INT, release_year INT, popularity INT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        co.country AS country,
        f.film_id,
        f.title,
        f.rating,
        l.name AS language,
        f.length,
        f.release_year,
        COUNT(*) AS popularity
    FROM 
        public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    INNER JOIN public.customer c ON p.customer_id = c.customer_id
    INNER JOIN public.address a ON c.address_id = a.address_id
    INNER JOIN public.city ci ON a.city_id = ci.city_id
    INNER JOIN public.country co ON ci.country_id = co.country_id
    INNER JOIN public.language l ON f.language_id = l.language_id
    WHERE 
        LOWER(co.country) = ANY (SELECT LOWER(x) FROM unnest(countries) AS x)
    GROUP BY 
        co.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
    ORDER BY 
        popularity DESC;
END;
$$ LANGUAGE plpgsql;



-- task 4. Create procedure language functions
-- Create a function that generates a list of movies available in stock 
-- based on a partial title match (e.g., movies containing the word 'love' in their title). 
-- The titles of these movies are formatted as '%...%', and if a movie with 
-- the specified title is not in stock, return a message indicating that it was not found.
-- The function should produce the result set in the following format 
-- (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
-- Query (example):select * from core.films_in_stock_by_title('%love%’);

CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(partial_title TEXT)
RETURNS TABLE(row_num INT, film_id INT, title TEXT, language TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY f.title) AS row_num,
        f.film_id,
        f.title,
        l.name AS language
    FROM 
        public.film f
    INNER JOIN public.language l ON f.language_id = l.language_id
    WHERE 
        f.title ILIKE partial_title
        AND EXISTS (
            SELECT 1
            FROM public.inventory i
            WHERE i.film_id = f.film_id
        );
        
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No movies found matching title: %', partial_title;
    END IF;
END;
$$ LANGUAGE plpgsql;

    

-- task 5. Create procedure language functions
-- Create a procedure language function called 'new_movie' that takes a movie title as a 
-- parameter and inserts a new movie with the given title in the film table. 
-- The function should generate a new unique film ID, set the rental rate to 4.99, 
-- the rental duration to three days, the replacement cost to 19.99. 
-- The release year and language are optional and by default should be current year 
-- and Klingon respectively. The function should also verify that 
-- the language exists in the 'language' table. 
-- Then, ensure that no such function has been created before; if so, replace it.

CREATE OR REPLACE FUNCTION public.new_movie(
    movie_title TEXT,
    release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    language TEXT DEFAULT 'Klingon'
)
RETURNS VOID AS $$
DECLARE
    lang_id INT;
BEGIN
    -- Check language
    SELECT language_id INTO lang_id FROM public.language WHERE LOWER(name) = LOWER(language);
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" does not exist.', language;
    END IF;

    -- Check for duplicate
    IF EXISTS (
        SELECT 1 FROM public.film 
        WHERE LOWER(title) = LOWER(movie_title) AND release_year = release_year
    ) THEN
        RAISE EXCEPTION 'Movie "%" already exists for year %.', movie_title, release_year;
    END IF;

    -- Insert movie
    INSERT INTO public.film (title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
    VALUES (movie_title, 4.99, 3, 19.99, release_year, lang_id);
END;
$$ LANGUAGE plpgsql;

