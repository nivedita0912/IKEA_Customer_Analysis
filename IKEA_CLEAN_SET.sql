
SELECT DATNAME FROM PG_DATABASE;

SELECT table_name
from information_schema.tables
where table_schema = 'public'
and table_type = 'BASE TABLE';

select * from public.old;
select * from public.new;
select count(*) as old_total_count from old;
select count(*) as new_total_count from new;

select count(*) as empty_customer from old where customerid is null;
select count(*) from old where customerid is null;


select count(*) as empty_invoice from old where invoice is null;
select count(*) as empty_invoice from new where invoice is null;

select count(*) as empty_description from old where description is null;
select count(*) as empty_description from new where description is null;

select count(*) as negative_quantity from old where quantity < 0 ;
select count(*) as negative_quantity from new where quantity < 0;

select count(*) as negative_price from public.old where price::NUMERIC <= 0;
select count(*) as negative_price from public.new where price::NUMERIC <= 0;

select count(*) as null_country from old where country is null;
select count(*) as null_country from new where country is null;

SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'old'
ORDER BY ordinal_position;

CREATE TABLE public.retailcombined AS
SELECT * FROM public.old
UNION ALL
SELECT * FROM public.new;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'retailcombined'
ORDER BY ordinal_position;

select * from public.retailcombined;

ALTER TABLE public.retailcombined
ALTER COLUMN "invoicedate"
TYPE TIMESTAMP
USING TO_TIMESTAMP("invoicedate", 'DD-MM-YYYY HH24:MI');

alter table public.retailcombined
 ALTER COLUMN "invoice" TYPE VARCHAR(20),
    ALTER COLUMN "stockcode" TYPE VARCHAR(30),
    ALTER COLUMN "description" TYPE TEXT,
    ALTER COLUMN "quantity" TYPE INTEGER USING "quantity"::INTEGER,
    ALTER COLUMN "invoicedate" TYPE TIMESTAMP USING "invoicedate"::TIMESTAMP,
    ALTER COLUMN "price" TYPE NUMERIC(10,2) USING "price"::NUMERIC(10,2),
    ALTER COLUMN "customerid" TYPE INTEGER USING "customerid"::INTEGER,
    ALTER COLUMN "country" TYPE VARCHAR(100);

select count(*) from retailcombined ;


with dupilcate_check as (
select ctid AS row_id, ROW_NUMBER() OVER (
 PARTITION BY invoice, stockcode, description,
 invoicedate, price, customerid, country
 ORDER BY customerid
)
as rowNumber
from public.retailcombined
)
select count(*)
FROM dupilcate_check
    WHERE rowNumber > 1
;

SELECT COUNT(*) FROM retailcombined;

select *
FROM dupilcate_check
    WHERE rowNumber > 1;

WITH duplicate_check AS (
    SELECT ctid AS row_id,
           ROW_NUMBER() OVER (
               PARTITION BY invoice, stockcode, description, quantity,
                            invoicedate, price, customerid, country
               ORDER BY ctid
           ) AS rownumber
    FROM public.retailcombined
)
DELETE FROM public.retailcombined
WHERE ctid IN (
    SELECT row_id
    FROM duplicate_check
    WHERE rownumber = 2
);


select count(*) from public.retailcombined;
