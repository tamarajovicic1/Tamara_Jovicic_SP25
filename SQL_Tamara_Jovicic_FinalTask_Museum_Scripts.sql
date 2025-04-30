-- 1. Create a new database
CREATE DATABASE museum_db;

-- 2. Create a new schema
CREATE SCHEMA IF NOT EXISTS museum_schema;

-- Set search_path to schema
SET search_path TO museum_schema;

-- 3. Create tables with primary and foreign keys

-- Item table
CREATE TABLE museum_schema.item (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(100) NOT NULL,
    acquisition_date DATE NOT NULL,
    storage_location_id INT REFERENCES museum_schema.storage_facility(storage_location_id)
);

-- StorageFacility table
CREATE TABLE museum_schema.storage_facility (
    storage_location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(255) NOT NULL UNIQUE,
    capacity INT NOT NULL CHECK (capacity > 0),
    current_occupancy INT DEFAULT 0 CHECK (current_occupancy >= 0)
);

-- Exhibition table
CREATE TABLE museum_schema.exhibition (
    exhibition_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    description TEXT
);

-- Ticket table
CREATE TABLE museum_schema.ticket (
    ticket_id SERIAL PRIMARY KEY,
    visitor_id INT REFERENCES museum_schema.visitor(visitor_id),
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    price DECIMAL(6,2) NOT NULL CHECK (price >= 0)
);

-- Visitor table
CREATE TABLE museum_schema.visitor (
    visitor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ItemExhibition (many-to-many) table
CREATE TABLE museum_schema.item_exhibition (
    item_id INT REFERENCES museum_schema.item(item_id),
    exhibition_id INT REFERENCES museum_schema.exhibition(exhibition_id),
    display_location VARCHAR(255),
    PRIMARY KEY (item_id, exhibition_id)
);

-- Department table
CREATE TABLE museum_schema.department (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    location VARCHAR(255)
);

-- Employee table
CREATE TABLE museum_schema.employee (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    hire_date DATE NOT NULL,
    department_id INT REFERENCES museum_schema.department(department_id)
);


-- Acquisition date must be after January 1. 2024.
ALTER TABLE museum_schema.item
ADD CONSTRAINT chk_item_acquisition_date CHECK (acquisition_date > DATE '2024-01-01');

-- Start date of exhibition must be after January 1. 2024.
ALTER TABLE museum_schema.exhibition
ADD CONSTRAINT chk_exhibition_start_date CHECK (start_date > DATE '2024-01-01');

-- Visitor email must not be null if provided (already handled with UNIQUE, but double check)
ALTER TABLE museum_schema.visitor
ALTER COLUMN email SET NOT NULL;

-- Ticket price must be non-negative (already included, just adding constraint name)
ALTER TABLE museum_schema.ticket
ADD CONSTRAINT chk_ticket_price_non_negative CHECK (price >= 0);

-- Employee hire date must be after January 1. 2020.
ALTER TABLE museum_schema.employee
ADD CONSTRAINT chk_employee_hire_date CHECK (hire_date > DATE '2020-01-01');

-- Adding a computed column for item age in years
CREATE OR REPLACE VIEW museum_schema.item_with_age AS
SELECT 
    i.*,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, i.acquisition_date))::INT AS item_age
FROM 
    museum_schema.item i;

-- Inserting sample data into visitor table
INSERT INTO museum_schema.visitor (first_name, last_name, email, visit_date)
VALUES
    ('Tamara', 'Jovicic', 'tamara.jovicic@email.com', CURRENT_DATE - 7),
    ('Bojana', 'Jovicic', 'bojana.jovicic@email.com', CURRENT_DATE - 17),
    ('Mina', 'Rogosic', 'mina.rogosic@email.com', CURRENT_DATE - 28),
    ('Isidora', 'Djurovic', 'isidora.djurovic@email.com', CURRENT_DATE - 16),
    ('Ana', 'Vujovic', 'ana.vujovic@email.com', CURRENT_DATE - 3),
    ('Jake', 'Peralta', 'jake.peralta@email.com', CURRENT_DATE - 9);

-- Inserting sample data into employee table
ALTER TABLE museum_schema.employee
  ALTER COLUMN hire_date SET DATA TYPE DATE;

INSERT INTO museum_schema.employee (first_name, last_name, email, position, hire_date)
VALUES
    ('Sara', 'Leah', 'sara.leah@email.com', 'Curator', CURRENT_DATE - 138),
    ('Daniel', 'Swift', 'daniel.swift@email.com', 'Manager', CURRENT_DATE - 95),
    ('Tammy', 'King', 'tammy.king@email.com', 'Security', CURRENT_DATE - 268),
    ('Matija', 'Miller', 'matija.miller@email.com', 'Assistant', CURRENT_DATE - 100),
    ('Emma', 'Davis', 'emma.davis@email.com', 'Janitor', CURRENT_DATE - 68),
    ('David', 'Moric', 'david.moric@email.com', 'Security', CURRENT_DATE - 156);

-- Inserting sample data into ticket table
INSERT INTO museum_schema.ticket (visitor_id, price, purchase_date)
VALUES
    (1, 20.00, CURRENT_DATE - 1),
    (2, 25.00, CURRENT_DATE - 3),
    (3, 30.00, CURRENT_DATE - 5),
    (4, 15.00, CURRENT_DATE - 7),
    (5, 22.50, CURRENT_DATE - 10),
    (6, 18.00, CURRENT_DATE - 12);

-- Inserting sample data into item table
INSERT INTO museum_schema.item (name, acquisition_date, description, type)
VALUES
    ('Mona Lisa', CURRENT_DATE - 120, 'Famous painting by Leonardo da Vinci', 'Painting'),
    ('Ancient Vase', CURRENT_DATE - 80, 'Clay vase from ancient Greece', 'Artifact'),
    ('Dinosaur Skull', CURRENT_DATE - 100, 'Skull from a Tyrannosaurus Rex', 'Specimen'),
    ('Greek Statue', CURRENT_DATE - 90, 'Statue of an ancient Greek philosopher', 'Artifact'),
    ('Medieval Sword', CURRENT_DATE - 60, 'A sword from the medieval era', 'Weapon'),
    ('Space Shuttle Model', CURRENT_DATE - 50, 'Model of the famous NASA shuttle', 'Artifact');

-- Inserting sample data into exhibition table
INSERT INTO museum_schema.exhibition (title, start_date, end_date, description)
VALUES
    ('Renaissance Art', CURRENT_DATE - 100, CURRENT_DATE - 50, 'Art'),
    ('Dinosaur Bones', CURRENT_DATE - 60, CURRENT_DATE - 30, 'Science'),
    ('Ancient Civilizations', CURRENT_DATE - 40, CURRENT_DATE - 10, 'History'),
    ('Space Exploration', CURRENT_DATE - 70, CURRENT_DATE - 30, 'Technology'),
    ('Medieval Times', CURRENT_DATE - 20, CURRENT_DATE + 10, 'History'),
    ('Modern Art', CURRENT_DATE - 5, CURRENT_DATE + 20, 'Art');

-- Insert sample data into storage_facility table
INSERT INTO museum_schema.storage_facility (location_name, capacity, current_occupancy)
VALUES
    ('Room A', 100, 50),
    ('Room B', 200, 150),
    ('Room C', 50, 30),
    ('Room D', 75, 60),
    ('Room E', 120, 100),
    ('Room F', 80, 40);

-- Function to update a specific column in a table based on the primary key
CREATE OR REPLACE FUNCTION museum_schema.update_item_data(
    p_item_id INT,              
    p_column_name VARCHAR,      
    p_new_value VARCHAR         
)
RETURNS VOID AS
$$
DECLARE
    v_sql TEXT;  
BEGIN
    -- Construct the dynamic SQL query to update the specified column
    v_sql := 'UPDATE museum_schema.item SET ' || p_column_name || ' = $1 WHERE item_id = $2';
    EXECUTE v_sql USING p_new_value, p_item_id;
    RAISE NOTICE 'Item with ID % updated successfully.', p_item_id;
END;
$$
LANGUAGE plpgsql;

-- Update the description column of the item with ID 1
SELECT museum_schema.update_item_data(1, 'description', 'Updated description for item 1, test');

--5.2. Create a function that adds a new transaction to a transaction table
CREATE TABLE museum_schema.museum_transaction (
    transaction_id SERIAL PRIMARY KEY,
    item_id INT NOT NULL,
    transaction_date DATE DEFAULT CURRENT_DATE,
    transaction_type VARCHAR(50) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    total_price DECIMAL(10, 2) NOT NULL CHECK (total_price >= 0)
);

-- Function to add a new transaction to the transaction table
CREATE OR REPLACE FUNCTION museum_schema.add_transaction(
    p_item_id INT,                
    p_transaction_type VARCHAR,   
    p_quantity INT,               
    p_total_price DECIMAL(10, 2)  
)
RETURNS VOID AS
$$
BEGIN
    INSERT INTO museum_schema.museum_transaction (item_id, transaction_type, quantity, total_price)
    VALUES (p_item_id, p_transaction_type, p_quantity, p_total_price);
    RAISE NOTICE 'Transaction for item ID % successfully added.', p_item_id;
END;
$$
LANGUAGE plpgsql;

-- Add a new purchase transaction for item with ID 1, 5 units, totaling 100.00
SELECT museum_schema.add_transaction(1, 'purchase', 5, 100.00);

-- Create a view for the most recently added quarter analytics
CREATE OR REPLACE VIEW museum_schema.recent_quarter_analytics AS
WITH quarter_dates AS (
    SELECT 
        date_trunc('quarter', CURRENT_DATE) AS quarter_start_date,
        date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months' - INTERVAL '1 day' AS quarter_end_date
),
recent_items AS (
    SELECT 
        i.name AS item_name,
        i.description AS item_description,
        i.type AS item_type,
        i.acquisition_date AS item_acquisition_date,
        sf.location_name AS storage_location
    FROM museum_schema.item i
    JOIN museum_schema.storage_facility sf
        ON i.storage_location_id = sf.storage_location_id,
    quarter_dates qd
    WHERE i.acquisition_date BETWEEN qd.quarter_start_date AND qd.quarter_end_date
),
recent_exhibitions AS (
    SELECT 
        e.title AS exhibition_name,
        e.description AS exhibition_description,
        e.start_date AS exhibition_start_date,
        e.end_date AS exhibition_end_date
    FROM museum_schema.exhibition e,
    quarter_dates qd
    WHERE e.start_date BETWEEN qd.quarter_start_date AND qd.quarter_end_date
)
SELECT 
    ri.item_name,
    ri.item_description,
    ri.item_type,
    ri.item_acquisition_date,
    ri.storage_location,
    re.exhibition_name,
    re.exhibition_description,
    re.exhibition_start_date,
    re.exhibition_end_date
FROM recent_items ri
LEFT JOIN recent_exhibitions re
    ON ri.item_acquisition_date <= re.exhibition_start_date
ORDER BY ri.item_acquisition_date DESC;

-- Create a read-only role for the manager
CREATE ROLE manager_read_only
    LOGIN
    NOINHERIT;

-- Grant SELECT privileges on all tables in the museum schema to the manager role
GRANT USAGE ON SCHEMA museum_schema TO manager_read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA museum_schema TO manager_read_only;

-- To ensure that future tables also have SELECT privileges granted
ALTER DEFAULT PRIVILEGES IN SCHEMA museum_schema
GRANT SELECT ON TABLES TO manager_read_only;	

-- Create a sample manager user and assign the role (you can create specific users as needed)
CREATE USER manager_user WITH PASSWORD 'test_password';
GRANT manager_read_only TO manager_user;

--The manager user can now log in and perform SELECT queries on all tables 
--in the museum schema


