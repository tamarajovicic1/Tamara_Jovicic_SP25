--Create table ‘table_to_delete’ and fill it with the query
CREATE TABLE table_to_delete AS
	SELECT 'veeeeeeery_long_string' || x AS col
    FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)

--Lookup how much space this table consumes with the query
SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS INDEX,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS TABLE
FROM ( 
    SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM ( 
        SELECT c.oid, nspname AS table_schema, 
               relname AS TABLE_NAME,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

-- Issue the following DELETE operation on ‘table_to_delete’
-- it took 31s to perfom this delete
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string', '')::int % 3 = 0;

--Lookup space consumption of the table after the DELETE - 575mb

--Perform the VACUUM FULL VERBOSE operation
--execute time - 21s
--storage - 383mb
--in output found 2655781 removable, 6666667 nonremovable row versions in 73536 pages
VACUUM FULL VERBOSE table_to_delete;

-- Recreate ‘table_to_delete’ table
DROP TABLE IF EXISTS table_to_delete;
--40s to execute
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

--Issue the following TRUNCATE operation
--1.172s to execute, so much faster then other deletion
--it deleted everything and left 0 bytes
TRUNCATE table_to_delete;
