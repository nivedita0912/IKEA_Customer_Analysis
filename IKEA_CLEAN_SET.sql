-- create table old(
--  Invoice VARCHAR(20),
--     StockCode VARCHAR(30),
--     Description TEXT,
--     Quantity INTEGER,
--     InvoiceDate VARCHAR(20),
--     Price VARCHAR(20),
--     CustomerID INTEGER,
--     Country VARCHAR(100)
-- );


-- create table new(
--  Invoice VARCHAR(20),
--     StockCode VARCHAR(30),
--     Description TEXT,
--     Quantity INTEGER,
--     InvoiceDate VARCHAR(20),
--     Price VARCHAR(20),
--     CustomerID INTEGER,
--     Country VARCHAR(100)
-- );
SELECT datname
FROM pg_database;

SELECT CURRENT_DATABASE();

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';


create table retailCombined
as 
select 
   Invoice,
    StockCode,
    Description,
    Quantity,
    TO_TIMESTAMP(InvoiceDate, 'DD-MM-YYYY HH24:MI') AS InvoiceDate,
    Price::NUMERIC(10,2) AS Price,
    CustomerID,
    Country
from old 
union all
select 
    Invoice,
    StockCode,
    Description,
    Quantity,
    TO_TIMESTAMP(InvoiceDate, 'DD-MM-YYYY HH24:MI') AS InvoiceDate,
    Price::NUMERIC(10,2) AS Price,
    CustomerID,
    Country
from new;

select * from retailcombined ;

select count(*) as null_ids from retailcombined where customerid is null;

select count(*) as negativeORzero from retailcombined where quantity <= 0;

select count(*) as null_description from retailcombined where description is null;

SELECT a.*, b.*
FROM retailcombined a
JOIN retailcombined b
ON a.Invoice = b.Invoice
AND a.StockCode = b.StockCode
AND a.ctid < b.ctid;

 
WITH removing_duplicate AS (
    SELECT
        ctid,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice, StockCode, Description,
                         Quantity, InvoiceDate, Price,
                         CustomerID, Country
            ORDER BY ctid
        ) AS rownumber
    FROM retailcombined
)
DELETE FROM retailcombined
WHERE ctid IN (
    SELECT ctid
    FROM removing_duplicate
    WHERE rownumber > 1
);

SELECT * FROM RETAILCOMBINED;

SELECT
    Invoice, StockCode, Description, Quantity,
    InvoiceDate, Price, CustomerID, Country,
    COUNT(*)
FROM retailcombined
GROUP BY
    Invoice, StockCode, Description, Quantity,
    InvoiceDate, Price, CustomerID, Country
HAVING COUNT(*) > 1;
