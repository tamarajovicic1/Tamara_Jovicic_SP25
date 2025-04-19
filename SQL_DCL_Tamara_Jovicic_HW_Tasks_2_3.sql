--Create a new user with the username "rentaluser" and the password "rentalpassword". 
--Give the user the ability to connect to the database but no other permissions.

CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';

--Grant "rentaluser" SELECT permission for the "customer" table. 

GRANT SELECT ON TABLE customer TO rentaluser;

--Сheck to make sure this permission works correctly—write a SQL query to select all customers.
--i changed in settings username and password to rentaluser.

SELECT * 
FROM customer;

--Create a new user group called "rental" and add "rentaluser" to the group.

CREATE ROLE rental;
GRANT rental TO rentaluser;

--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 

GRANT INSERT, UPDATE ON rental TO rental;

--Insert a new row and update one existing row in the "rental" table under that role. 

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (CURRENT_TIMESTAMP, 1, 1, 1);

UPDATE rental
SET return_date = CURRENT_TIMESTAMP
WHERE rental_id = 1;
--Testing
SELECT * FROM rental WHERE rental_id = 1;

--Revoke the "rental" group's INSERT permission for the "rental" table. 

REVOKE INSERT ON TABLE rental FROM rental;

--Try to insert new rows into the "rental" table make sure this action is denied.

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
VALUES (CURRENT_TIMESTAMP, 1, 1, 1);

--Create a personalized role for any customer already existing in the dvd_rental database.
-- The name of the role name must be client_tamara_jovicic.
--The customer's payment and rental history must not be empty. 
-- it exists because i made it for some task

SELECT c.customer_id
FROM customer c
WHERE first_name = 'Tamara' AND last_name = 'Jovicic'
  AND EXISTS (SELECT 1 FROM payment p WHERE p.customer_id = c.customer_id)
  AND EXISTS (SELECT 1 FROM rental r WHERE r.customer_id = c.customer_id);


ALTER ROLE client_tamara_jovicic WITH LOGIN PASSWORD 'tamarajovicic';

GRANT SELECT ON rental TO client_tamara_jovicic;
GRANT SELECT ON payment TO client_tamara_jovicic;
GRANT SELECT ON customer TO client_tamara_jovicic;
--testing when user is client_tamara_jovicic, it works!
SELECT * 
FROM rental
WHERE customer_id = (
  SELECT customer_id 
  FROM customer 
  WHERE first_name = 'Tamara' AND last_name = 'Jovicic'
);

--Task 3. Implement row-level security
--Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
--Configure that role so that the customer can only access their own data in the "rental" 
--and "payment" tables. Write a query to make sure this user sees only their own data.

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY rental_customer_policy
  ON rental
  FOR SELECT
  TO client_tamara_jovicic
  USING (customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Tamara' AND last_name = 'Jovicic'));

CREATE POLICY payment_customer_policy
  ON payment
  FOR SELECT
  TO client_tamara_jovicic
  USING (customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Tamara' AND last_name = 'Jovicic'));

--testing as client, it works!
SELECT * FROM rental;
SELECT * FROM payment;



