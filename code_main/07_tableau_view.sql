-- 07_tableau_view.sql
CREATE SCHEMA IF NOT EXISTS walmart;

DROP VIEW IF EXISTS walmart.vw_tableau CASCADE;
CREATE VIEW walmart.vw_tableau AS
SELECT
  fp.purchase_date                          AS order_date,
  dd.year, dd.month, dd.yyyymm, dd.dow,
  fp.city,
  fp.product_name, fp.category,
  fp.purchase_amount, fp.discount_applied, fp.rating, fp.payment_method,
  fp.repeat_customer,
  dc.age, dc.age_band, dc.gender,

  -- Scores & actions
  ps.product_score, ps.quartile AS product_quartile, ps.recommended_action,
  cs.city_score,    cs.quartile AS city_quartile

FROM walmart.fact_purchases fp
LEFT JOIN walmart.dim_date     dd ON dd.date = fp.purchase_date
LEFT JOIN walmart.dim_customer dc ON dc.customer_id = fp.customer_id
LEFT JOIN walmart.vw_product_scorecard ps
       ON ps.product_name = fp.product_name AND ps.category = fp.category
LEFT JOIN walmart.vw_city_scorecard    cs
       ON cs.city = fp.city;
