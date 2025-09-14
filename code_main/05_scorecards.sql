-- 05_scorecards.sql
CREATE SCHEMA IF NOT EXISTS walmart;

-- Product scorecard (percentile ranks + weighted score)
DROP VIEW IF EXISTS walmart.vw_product_scorecard CASCADE;
CREATE VIEW walmart.vw_product_scorecard AS
WITH s AS (
  SELECT
    kp.*,
    PERCENT_RANK() OVER (ORDER BY kp.revenue)             AS p_revenue,
    PERCENT_RANK() OVER (ORDER BY kp.orders)              AS p_orders,
    PERCENT_RANK() OVER (ORDER BY kp.revenue_per_day)     AS p_velocity,
    PERCENT_RANK() OVER (ORDER BY kp.avg_rating)          AS p_rating,
    PERCENT_RANK() OVER (ORDER BY kp.repeat_share)        AS p_repeat,
    1 - PERCENT_RANK() OVER (ORDER BY COALESCE(kp.discount_share,0))
                                                         AS p_low_discount
  FROM walmart.vw_kpi_product kp
),
w AS (
  SELECT
    s.*,
    -- weights: revenue 35%, orders 20%, velocity 15%, rating 15%, repeat 10%, low-discount 5%
    (0.35*s.p_revenue + 0.20*s.p_orders + 0.15*s.p_velocity +
     0.15*s.p_rating  + 0.10*s.p_repeat  + 0.05*s.p_low_discount) AS product_score
  FROM s
),
band AS (
  SELECT w.*, NTILE(4) OVER (ORDER BY w.product_score DESC) AS quartile
  FROM w
)
SELECT
  b.product_name,
  b.category,
  b.orders, b.revenue, b.aov, b.avg_rating, b.discount_share, b.repeat_share,
  b.revenue_per_day,
  b.product_score, b.quartile,
  CASE
    WHEN b.quartile = 1 AND COALESCE(b.discount_share,0) < 0.15 THEN 'PROMOTE / RESTOCK'
    WHEN b.quartile <= 2 AND COALESCE(b.discount_share,0) >= 0.25 THEN 'QUALITY REVIEW / REPRICE'
    WHEN b.quartile = 4 THEN 'DISCOUNT or DISCONTINUE'
    ELSE 'MAINTAIN'
  END AS recommended_action
FROM band b;

-- City scorecard
DROP VIEW IF EXISTS walmart.vw_city_scorecard CASCADE;
CREATE VIEW walmart.vw_city_scorecard AS
WITH s AS (
  SELECT
    kc.*,
    PERCENT_RANK() OVER (ORDER BY kc.revenue)             AS p_revenue,
    PERCENT_RANK() OVER (ORDER BY kc.aov)                 AS p_aov,
    PERCENT_RANK() OVER (ORDER BY kc.avg_rating)          AS p_rating,
    PERCENT_RANK() OVER (ORDER BY kc.repeat_share)        AS p_repeat,
    1 - PERCENT_RANK() OVER (ORDER BY COALESCE(kc.discount_share,0))
                                                         AS p_low_discount
  FROM walmart.vw_kpi_city kc
),
w AS (
  SELECT
    s.*,
    (0.45*s.p_revenue + 0.20*s.p_aov + 0.15*s.p_rating + 0.10*s.p_repeat + 0.10*s.p_low_discount)
      AS city_score
  FROM s
)
SELECT
  w.*,
  NTILE(4) OVER (ORDER BY w.city_score DESC) AS quartile
FROM w;

-- RFM segmentation (quartiles)
DROP VIEW IF EXISTS walmart.vw_customer_rfm CASCADE;
CREATE VIEW walmart.vw_customer_rfm AS
WITH q AS (
  SELECT
    r.*,
    NTILE(4) OVER (ORDER BY r.recency_days ASC) AS r_score,   -- smaller is better
    NTILE(4) OVER (ORDER BY r.frequency DESC)   AS f_score,
    NTILE(4) OVER (ORDER BY r.monetary  DESC)   AS m_score
  FROM walmart.vw_rfm_base r
)
SELECT
  q.*,
  (q.r_score::text || q.f_score::text || q.m_score::text) AS rfm_code,
  CASE
    WHEN r_score = 4 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
    WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
    WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
    WHEN r_score <= 2 AND f_score <= 2                  THEN 'Hibernating'
    ELSE 'Potential Loyalist'
  END AS segment
FROM q;
