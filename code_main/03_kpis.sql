-- 04_kpis.sql

-- Core KPIs & RFM built from walmart.fact_purchases

CREATE SCHEMA IF NOT EXISTS walmart;

-- Safety check:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'walmart'
      AND table_name   = 'fact_purchases'
  ) THEN
    RAISE EXCEPTION 'walmart.fact_purchases not found. Run 03_model.sql first.';
  END IF;
END
$$;

-- Base 
DROP VIEW IF EXISTS walmart.vw_kpi_base CASCADE;
CREATE VIEW walmart.vw_kpi_base AS
SELECT *
FROM walmart.fact_purchases
;


-- Product KPIs
DROP VIEW IF EXISTS walmart.vw_kpi_product CASCADE;
CREATE VIEW walmart.vw_kpi_product AS
WITH agg AS (
  SELECT
    fp.product_name,
    fp.category,
    COUNT(*)                                   AS orders,
    SUM(fp.purchase_amount)                    AS revenue,
    AVG(fp.purchase_amount)                    AS aov,
    AVG(NULLIF(fp.rating,0))                   AS avg_rating,
    AVG(CASE
          WHEN fp.discount_applied IS TRUE  THEN 1
          WHEN fp.discount_applied IS FALSE THEN 0
          ELSE NULL
        END)::numeric                          AS discount_share,
    AVG(CASE
          WHEN fp.repeat_customer IS TRUE  THEN 1
          WHEN fp.repeat_customer IS FALSE THEN 0
          ELSE NULL
        END)::numeric                          AS repeat_share,
    COUNT(DISTINCT fp.purchase_date)           AS active_days
  FROM walmart.vw_kpi_base fp
  GROUP BY fp.product_name, fp.category
)
SELECT
  a.*,
  CASE WHEN a.active_days > 0
       THEN a.revenue::numeric / a.active_days
       ELSE 0 END                              AS revenue_per_day
FROM agg a
;


-- City KPIs
DROP VIEW IF EXISTS walmart.vw_kpi_city CASCADE;
CREATE VIEW walmart.vw_kpi_city AS
SELECT
  fp.city,
  COUNT(*)                                   AS orders,
  SUM(fp.purchase_amount)                    AS revenue,
  AVG(fp.purchase_amount)                    AS aov,
  AVG(NULLIF(fp.rating,0))                   AS avg_rating,
  AVG(CASE
        WHEN fp.discount_applied IS TRUE  THEN 1
        WHEN fp.discount_applied IS FALSE THEN 0
        ELSE NULL
      END)::numeric                           AS discount_share,
  AVG(CASE
        WHEN fp.repeat_customer IS TRUE  THEN 1
        WHEN fp.repeat_customer IS FALSE THEN 0
        ELSE NULL
      END)::numeric                           AS repeat_share
FROM walmart.vw_kpi_base fp
GROUP BY fp.city
;


-- RFM (customer-level)
DROP VIEW IF EXISTS walmart.vw_rfm_base CASCADE;
CREATE VIEW walmart.vw_rfm_base AS
WITH last_d AS (
  SELECT MAX(purchase_date) AS max_d
  FROM walmart.vw_kpi_base
)
SELECT
  fp.customer_id,
  (SELECT max_d FROM last_d) - MAX(fp.purchase_date) AS recency_days,  -- integer interval -> integer days
  COUNT(*)                                           AS frequency,
  SUM(fp.purchase_amount)                            AS monetary
FROM walmart.vw_kpi_base fp
GROUP BY fp.customer_id
;


-- checks
SELECT COUNT(*) AS fact_rows     FROM walmart.fact_purchases;
SELECT COUNT(*) AS prod_kpi_rows FROM walmart.vw_kpi_product;
SELECT COUNT(*) AS city_kpi_rows FROM walmart.vw_kpi_city;
SELECT COUNT(*) AS rfm_rows      FROM walmart.vw_rfm_base;
