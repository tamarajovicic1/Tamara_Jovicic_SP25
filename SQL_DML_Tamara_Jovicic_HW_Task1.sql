--Adding three films in table films.
--I filled rental_rate and rental_durations as 4.99, 9.99, 19.99 and 1, 2 and 3 weeks respectively.
insert into film (title, release_year, rental_rate, rental_duration, language_id)
values
	('Twilight', 2008, 4.99, 7, (SELECT language_id FROM language WHERE name = 'English' LIMIT 1)),
	('Red Notice', 2021, 9.99, 14, (SELECT language_id FROM language WHERE name = 'English' LIMIT 1)),
	('Oppenheimer', 2023, 19.99, 21, (SELECT language_id FROM language WHERE name = 'English' LIMIT 1))
returning film_id;

--Adding leading roles of three films
insert into actor (first_name, last_name)
values
	('Kristen', 'Stewart'),
	('Robert', 'Pattinson'),
	('Gal', 'Gadot'),
	('Dwayne', 'Johnson'),
	('Ryan', 'Reynolds'),
	('Cilian', 'Murphy'),
	('Robert', 'Downey Jr.')
returning actor_id;

--Before i add my favorite movies to any store's inventory i have to join films and actors
insert into film_actor (actor_id, film_id)
select a.actor_id, f.film_id
from actor a
join film f on (
	(f.title = 'Twilight' and (a.first_name, a.last_name) in (('Kristen', 'Stewart'), ('Robert', 'Pattinson')))
	or (f.title = 'Red Notice' and (a.first_name, a.last_name) in (('Gal', 'Gadot'), ('Dwayne', 'Johnson'), ('Ryan', 'Reynolds')))
	or (f.title = 'Oppenheimer' and (a.first_name, a.last_name) in (('Cilian', 'Murphy'), ('Robert', 'Downey Jr.'))))

--Adding my favorite movies to any store's inventory(limit 1 if exist duplicate)
insert into inventory (film_id, store_id)
values 
	((select film_id from film where title = 'Twilight' limit 1), 1),
	((select film_id from film where title = 'Red Notice' limit 1), 1),
	((select film_id from film where title = 'Oppenheimer' limit 1), 1);

--Alter any existing customer in the database with at least 43 rental and 43 payment records. 
--Change their personal data to yours (first name, last name, address, etc.). 
--You can use any existing address from the "address" table. 
--Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.
--updating customer with my name
update customer 
set first_name = 'Tamara',
	last_name = 'Jovicic',
	email = 'tamarajovicic44@gmail.com'
where customer_id = (
	select customer_id
	from customer 
	where customer_id in(
		select c.customer_id
		from customer c
		join rental r on c.customer_id = r.customer_id
		join payment p on c.customer_id = p.customer_id 
		group by c.customer_id 
		having count(distinct r.rental_id) >= 43 and count(distinct p.payment_id) >= 43 
		limit 1))
returning customer_id;

--Removing any records related to me (as a customer) from all tables except 'Customer' and 'Inventory'
delete from payment where customer_id = (select customer_id from customer where upper(first_name) = upper('Tamara') and upper(last_name) = upper('Jovicic'));
delete from rental where customer_id = (select customer_id from customer where upper(first_name) = upper('Tamara') and upper(last_name) = upper('Jovicic'));

--Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
--(Note: to insert the payment_date into the table payment, 
--you can create a new partition (see the scripts to install the training database ) 
--or add records for the first half of 2017)
--add rental for three films
insert into payment (customer_id, staff_id, rental_id, amount, payment_date)
select r.customer_id, 
       1 as staff_id,
       r.rental_id,
       f.rental_rate,
       date '2017-06-15' as payment_date
from rental r
join inventory i on r.inventory_id = i.inventory_id
join film f on f.film_id = i.film_id
where r.customer_id = (
    select customer_id 
    from customer 
    where upper(first_name) = upper('Tamara') 
      and upper(last_name)  = upper('Jovicic')
)
returning payment_id;













