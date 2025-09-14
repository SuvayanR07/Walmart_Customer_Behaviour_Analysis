CREATE SCHEMA IF NOT EXISTS walmart;

DROP TABLE IF EXISTS walmart.stg_purchases;
CREATE TABLE walmart.stg_purchases (
  Customer_ID        TEXT,
  Age                TEXT,
  Gender             TEXT,
  City               TEXT,
  Category           TEXT,
  Product_Name       TEXT,
  Purchase_Date      TEXT,
  Purchase_Amount    TEXT,
  Payment_Method     TEXT,
  Discount_Applied   TEXT,
  Rating             TEXT,
  Repeat_Customer    TEXT
);

COPY walmart.stg_purchases
FROM '/Volumes/Suvayan/Study/Resume/Professional Project/SQL_customerbehaviour_project/csv_files/Walmart_customer_purchases.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', NULL '', ENCODING 'UTF8');

-- To check data
SELECT COUNT(*) AS rows_loaded FROM walmart.stg_purchases;
SELECT * FROM walmart.stg_purchases;

-- To check table format
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'walmart'
  AND table_name   = 'fact_purchases';
