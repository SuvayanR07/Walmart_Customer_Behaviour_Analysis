-- 99_sanity_checks.sql
SELECT 'fact_rows' AS check_name, COUNT(*) AS value FROM walmart.fact_purchases
UNION ALL SELECT 'kpi_product_rows', COUNT(*) FROM walmart.vw_kpi_product
UNION ALL SELECT 'kpi_city_rows',    COUNT(*) FROM walmart.vw_kpi_city
UNION ALL SELECT 'rfm_rows',         COUNT(*) FROM walmart.vw_customer_rfm;

-- Nulls check
SELECT 'null_dates_in_fact' AS check_name, COUNT(*) AS value
FROM walmart.fact_purchases WHERE purchase_date IS NULL;

SELECT 'neg_or_zero_amounts' AS check_name, COUNT(*) AS value
FROM walmart.fact_purchases WHERE purchase_amount <= 0;

-- Discount effectiveness rows with suspicious negative uplift
SELECT * FROM walmart.vw_discount_effectiveness
WHERE revenue_uplift_ratio < 0
ORDER BY revenue_uplift_ratio ASC
LIMIT 20;

SELECT * FROM walmart.vw_kpi_product LIMIT 10;


-- tableau_user with the username
GRANT USAGE ON SCHEMA walmart TO tableau_user;
GRANT SELECT ON ALL TABLES IN SCHEMA walmart TO tableau_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA walmart TO tableau_user;

-- ensure future objects are readable
ALTER DEFAULT PRIVILEGES IN SCHEMA walmart
GRANT SELECT ON TABLES TO tableau_user;


-- DB where objects are created
SELECT current_database();         
SELECT inet_server_addr(), inet_server_port();
SELECT current_user;
