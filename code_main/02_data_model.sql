CREATE SCHEMA IF NOT EXISTS walmart;

DROP TABLE IF EXISTS walmart.fact_purchases CASCADE;

CREATE TABLE walmart.fact_purchases AS
SELECT
 
  TRIM(CAST(s.Customer_ID AS TEXT)) AS customer_id,

  -- Age
  CASE
    WHEN s.Age IS NULL THEN NULL
    WHEN TRIM(CAST(s.Age AS TEXT)) = '' THEN NULL
    WHEN CAST(s.Age AS TEXT) ~ '^\d+$' AND CAST(s.Age AS INT) > 0 THEN CAST(s.Age AS INT)
    ELSE NULL
  END AS age,

  INITCAP(TRIM(CAST(s.Gender AS TEXT)))       AS gender,
  INITCAP(TRIM(CAST(s.City AS TEXT)))         AS city,
  INITCAP(TRIM(CAST(s.Category AS TEXT)))     AS category,
  INITCAP(TRIM(CAST(s.Product_Name AS TEXT))) AS product_name,

  -- Dates
  CAST(s.Purchase_Date AS DATE) AS purchase_date,

  -- Amounts
  GREATEST(
    COALESCE(NULLIF(TRIM(CAST(s.Purchase_Amount AS TEXT)), '')::NUMERIC, 0),
    0
  )::NUMERIC(12,2)                            AS purchase_amount,

  INITCAP(TRIM(CAST(s.Payment_Method AS TEXT))) AS payment_method,

  -- Booleans
  CASE
    WHEN LOWER(TRIM(CAST(s.Discount_Applied AS TEXT))) IN ('t','true','1','yes','y') THEN TRUE
    WHEN LOWER(TRIM(CAST(s.Discount_Applied AS TEXT))) IN ('f','false','0','no','n')  THEN FALSE
    ELSE NULL
  END AS discount_applied,

  -- Rating
  CASE
    WHEN s.Rating IS NULL THEN NULL
    WHEN TRIM(CAST(s.Rating AS TEXT)) = '' THEN NULL
    ELSE NULLIF(TRIM(CAST(s.Rating AS TEXT))::NUMERIC, 0)
  END::NUMERIC(3,1) AS rating,

  CASE
    WHEN LOWER(TRIM(CAST(s.Repeat_Customer AS TEXT))) IN ('t','true','1','yes','y') THEN TRUE
    WHEN LOWER(TRIM(CAST(s.Repeat_Customer AS TEXT))) IN ('f','false','0','no','n')  THEN FALSE
    ELSE NULL
  END AS repeat_customer

FROM walmart.stg_purchases s
WHERE s.Purchase_Date IS NOT NULL
  AND TRIM(CAST(s.Customer_ID  AS TEXT)) <> ''
  AND TRIM(CAST(s.Product_Name AS TEXT)) <> '';


ALTER TABLE walmart.fact_purchases
  ALTER COLUMN purchase_date SET NOT NULL,
  ALTER COLUMN customer_id   SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_fact_date      ON walmart.fact_purchases(purchase_date);
CREATE INDEX IF NOT EXISTS idx_fact_product   ON walmart.fact_purchases(product_name);
CREATE INDEX IF NOT EXISTS idx_fact_category  ON walmart.fact_purchases(category);
CREATE INDEX IF NOT EXISTS idx_fact_customer  ON walmart.fact_purchases(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_city      ON walmart.fact_purchases(city);


-- DIM: dim_date 

DROP TABLE IF EXISTS walmart.dim_date CASCADE;
CREATE TABLE walmart.dim_date AS
SELECT DISTINCT
  purchase_date                          AS date,
  EXTRACT(YEAR  FROM purchase_date)::int AS year,
  EXTRACT(MONTH FROM purchase_date)::int AS month,
  TO_CHAR(purchase_date, 'YYYY-MM')      AS yyyymm,
  EXTRACT(DOW   FROM purchase_date)::int AS dow
FROM walmart.fact_purchases;
ALTER TABLE walmart.dim_date ADD PRIMARY KEY (date);

-- DIM: dim_customer  --

DROP TABLE IF EXISTS walmart.dim_customer CASCADE;
CREATE TABLE walmart.dim_customer AS
SELECT DISTINCT
  customer_id,
  age,
  CASE
    WHEN age IS NULL                 THEN NULL
    WHEN age < 20                    THEN '<20'
    WHEN age BETWEEN 20 AND 29       THEN '20s'
    WHEN age BETWEEN 30 AND 39       THEN '30s'
    WHEN age BETWEEN 40 AND 49       THEN '40s'
    WHEN age BETWEEN 50 AND 59       THEN '50s'
    ELSE '60+'
  END AS age_band,
  gender,
  city
FROM walmart.fact_purchases
WHERE customer_id IS NOT NULL;
ALTER TABLE walmart.dim_customer ADD PRIMARY KEY (customer_id);

-- DIM: dim_product

DROP TABLE IF EXISTS walmart.dim_product CASCADE;
CREATE TABLE walmart.dim_product AS
SELECT DISTINCT
  md5(coalesce(product_name,'') || '|' || coalesce(category,'')) AS product_key,
  product_name,
  category
FROM walmart.fact_purchases
WHERE product_name IS NOT NULL OR category IS NOT NULL;
ALTER TABLE walmart.dim_product ADD PRIMARY KEY (product_key);
