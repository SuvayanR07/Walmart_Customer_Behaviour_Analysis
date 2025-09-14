-- 06_discount_effectiveness.sql
CREATE SCHEMA IF NOT EXISTS walmart;

DROP VIEW IF EXISTS walmart.vw_discount_effectiveness CASCADE;
CREATE VIEW walmart.vw_discount_effectiveness AS
WITH base AS (
  SELECT
    fp.product_name,
    fp.category,
    fp.discount_applied,
    COUNT(*)                  AS orders,
    SUM(fp.purchase_amount)   AS revenue,
    AVG(fp.purchase_amount)   AS aov
  FROM walmart.vw_kpi_base fp
  GROUP BY fp.product_name, fp.category, fp.discount_applied
),
wide AS (
  SELECT
    product_name,
    category,
    COALESCE(SUM(CASE WHEN discount_applied THEN orders  END),0) AS orders_disc,
    COALESCE(SUM(CASE WHEN NOT discount_applied THEN orders END),0) AS orders_nodisc,
    COALESCE(SUM(CASE WHEN discount_applied THEN revenue END),0) AS revenue_disc,
    COALESCE(SUM(CASE WHEN NOT discount_applied THEN revenue END),0) AS revenue_nodisc,
    COALESCE(AVG(CASE WHEN discount_applied THEN aov END),0)     AS aov_disc,
    COALESCE(AVG(CASE WHEN NOT discount_applied THEN aov END),0) AS aov_nodisc
  FROM base
  GROUP BY product_name, category
)
SELECT
  w.*,
  CASE WHEN revenue_nodisc > 0
       THEN (w.revenue_disc - w.revenue_nodisc) / w.revenue_nodisc
       ELSE NULL END AS revenue_uplift_ratio,
  CASE WHEN orders_nodisc > 0
       THEN (w.orders_disc  - w.orders_nodisc)  / w.orders_nodisc
       ELSE NULL END AS orders_uplift_ratio
FROM wide w;
