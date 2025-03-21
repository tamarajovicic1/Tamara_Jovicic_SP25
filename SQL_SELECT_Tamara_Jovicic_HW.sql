-- 1. All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
select 
	f.title, 
	f.release_year, 
	f.rental_rate 
from film f 
-- joining film table and film_category table
inner join film_category fc on f.film_id = fc.film_id
inner join category c on c.category_id = fc.category_id 
-- selecting only Animation category 
where c.name = 'Animation'
	and f.release_year between 2017 and 2019
	and f.rental_rate  > 1
order by f.title asc;



-- 2. The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
select 
-- address of the store
    concat(a.address, ' ', coalesce(a.address2, '')) as full_address, 
-- all revenue
    sum(p.amount) as revenue
from store s
-- joining address, staff, rental and payment.
inner join address a on s.address_id = a.address_id
inner join staff st on s.store_id = st.store_id
inner join rental r on st.staff_id = r.staff_id
inner join payment p on p.rental_id = r.rental_id
WHERE p.payment_date > '2017-03-31'
group by full_address
-- showing the best stores by revenue from the best
order by revenue desc;



-- 3. Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
select 
	a.first_name, 
	a.last_name, 
	count(f.film_id) as number_of_movies
from actor a 
inner join film_actor fa on fa.actor_id = a.actor_id
inner join film f on fa.film_id = f.film_id
where f.release_year > 2015
-- group by actors name
group by a.first_name, a.last_name
order by number_of_movies desc
-- only top five
limit 5;



-- 4. Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)
select 
    f.release_year,
    count(case when c.name = 'Drama' then f.film_id end) as number_of_drama_movies,
    count(case when c.name = 'Travel' then f.film_id end) as number_of_travel_movies,
    count(case when c.name = 'Documentary' then f.film_id end) as number_of_documentary_movies
from film f
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id
-- showing only drama, travel and documetary movies
where c.name in ('Drama', 'Travel', 'Documentary')
-- group by year and show by newest year
group by f.release_year
order by f.release_year desc;



-- 5. Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
-- Assumptions: 
-- staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
-- if staff processed the payment then he works in the same store; 
-- take into account only payment_date
select 
    st.staff_id,
    st.first_name, 
    st.last_name,
    st.store_id as last_store_worked,  
    sum(p.amount) as total_revenue 
from staff st
inner join payment p on p.staff_id = st.staff_id
-- only payments from 2017.
where extract(year from p.payment_date) = 2017  
group by st.staff_id, st.first_name, st.last_name, st.store_id  
-- order by revenue from biggest
order by total_revenue desc 
-- only top three
limit 3;



-- 6. Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system
select 
    f.title, 
    count(r.rental_id) as number_of_rentals,
    case 
	    -- the MPA rating
        when f.rating = 'G' then 'All ages'
        when f.rating = 'PG' then '10+'
        when f.rating = 'PG-13' then '13+'
        when f.rating = 'R' then '17+'
        when f.rating = 'NC-17' then '18+'
        else 'Unknown'
    end as expected_age
from film f
inner join inventory i on f.film_id = i.film_id
inner join rental r on i.inventory_id = r.inventory_id
-- group by title and rating, top five movies
group by f.title, f.rating
order by number_of_rentals desc
limit 5;



-- Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--The task can be interpreted in various ways, and here are a few options:
--V1: gap between the latest release_year and current year per each actor;
select 
    a.actor_id,
    a.first_name, 
    a.last_name,
    -- last movie year that actor was in the movie
    max(f.release_year) as last_movie_year,
    -- how many years he/she wasn't in movies from now(2025)
    2025 - max(f.release_year) as years_since_last_movie
from actor a
inner join film_actor fa on a.actor_id = fa.actor_id
inner join film f on fa.film_id = f.film_id
group by a.actor_id, a.first_name, a.last_name
order by years_since_last_movie desc
-- only top five with longest periods of time, group by actor
limit 5;

