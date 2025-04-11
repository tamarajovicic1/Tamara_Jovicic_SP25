-- task 1. Create a view
-- Create a view called 'sales_revenue_by_category_qtr' 
-- that shows the film category and total sales revenue for the current quarter and year. 
-- The view should only display categories with at least one sale in the current quarter. 
-- Note: when the next quarter begins, it will be considered as the current quarter.

create or replace view sales_revenue_by_category_qtr as
select 
    fc.name as category_name,
    sum(s.amount) as total_sales_revenue
from 
    sales s
join 
    films f on s.film_id = f.film_id
join 
    film_categories fc on f.category_id = fc.category_id
where 
    extract(quarter from s.sale_date) = extract(quarter from current_date) 
    and extract(year from s.sale_date) = extract(year from current_date)
group by 
    fc.name
having 
    sum(s.amount) > 0;


-- task 2. Create a query language functions
-- Create a query language function called 'get_sales_revenue_by_category_qtr' 
-- that accepts one parameter representing the current quarter and year 
-- and returns the same result as the 'sales_revenue_by_category_qtr' view.

create or replace function get_sales_revenue_by_category_qtr(current_quarter int, current_year int)
returns table(category_name text, total_sales_revenue numeric) as $$
begin
    return query
    select 
        fc.name as category_name,
        sum(s.amount) as total_sales_revenue
    from 
        sales s
    join 
        films f on s.film_id = f.film_id
    join 
        film_categories fc on f.category_id = fc.category_id
    where 
        extract(quarter from s.sale_date) = current_quarter 
        and extract(year from s.sale_date) = current_year
    group by 
        fc.name
    having 
        sum(s.amount) > 0;
end;
$$ language plpgsql;

-- task 3. Create procedure language functions
-- Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
-- The function should format the result set as follows:
-- Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);

create or replace function most_popular_films_by_countries(countries text[])
returns table(country text, film_id int, title text, rating text, language text, length int, release_year int, popularity int) as $$
begin
    return query
    select 
        c.country_name,
        f.film_id,
        f.title,
        f.rating,
        l.name as language,
        f.length,
        f.release_year,
        count(*) as popularity
    from 
        sales s
    join 
        films f on s.film_id = f.film_id
    join 
        customers c on s.customer_id = c.customer_id
    join 
        languages l on f.language_id = l.language_id
    where 
        c.country_name = any(countries)
    group by 
        c.country_name, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
    order by 
        popularity desc;
end;
$$ language plpgsql;


-- task 4. Create procedure language functions
-- Create a function that generates a list of movies available in stock 
-- based on a partial title match (e.g., movies containing the word 'love' in their title). 
-- The titles of these movies are formatted as '%...%', and if a movie with 
-- the specified title is not in stock, return a message indicating that it was not found.
-- The function should produce the result set in the following format 
-- (note: the 'row_num' field is an automatically generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).
-- Query (example):select * from core.films_in_stock_by_title('%love%’);

create or replace function films_in_stock_by_title(partial_title text)
returns table(row_num int, film_id int, title text, language text, customer_name text, rental_date date) as $$
declare
    movie record;
    row_number int := 0; -- row counter
begin
    for movie in
        select 
            f.film_id,
            f.title,
            l.name as language,
            c.first_name || ' ' || c.last_name as customer_name,
            r.rental_date
        from 
            films f
        join 
            inventory s on f.film_id = s.film_id
        join 
            languages l on f.language_id = l.language_id
        left join 
            rentals r on f.film_id = r.film_id
        left join 
            customers c on r.customer_id = c.customer_id
        where 
            f.title like partial_title 
            and s.available_stock > 0
            and r.rental_date is not null  -- if exists
    loop
        row_number := row_number + 1; 
        row_num := row_number; 
        return next movie;
    end loop;
    
    -- if not exists
    if row_number = 0 then
        raise exception 'no movies found matching title: %', partial_title;
    end if;
end;
$$ language plpgsql;

-- task 5. Create procedure language functions
-- Create a procedure language function called 'new_movie' that takes a movie title as a 
-- parameter and inserts a new movie with the given title in the film table. 
-- The function should generate a new unique film ID, set the rental rate to 4.99, 
-- the rental duration to three days, the replacement cost to 19.99. 
-- The release year and language are optional and by default should be current year 
-- and Klingon respectively. The function should also verify that 
-- the language exists in the 'language' table. 
-- Then, ensure that no such function has been created before; if so, replace it.

create or replace function new_movie(movie_title text, release_year int default extract(year from current_date), language text default 'klingon')
returns void as $$
declare
    lang_id int;
begin
    -- if exists
    select language_id into lang_id from languages where name = language;
    if not found then
        raise exception 'language % does not exist', language;
    end if;

    -- add new movie
    insert into films (title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
    values (movie_title, 4.99, 3, 19.99, release_year, lang_id);

    -- no duplicates
    if exists (select 1 from films where title = movie_title and release_year = release_year) then
        raise exception 'movie with the title % already exists', movie_title;
    end if;
end;
$$ language plpgsql;
