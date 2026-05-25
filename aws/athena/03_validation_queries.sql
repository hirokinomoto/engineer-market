-- Validation queries for Amazon Athena tables and views

-- 1. Row counts for external tables
SELECT
  'estat_job_market_2012_2022' AS table_name,
  COUNT(*) AS row_count
FROM engineer_market.estat_job_market_2012_2022

UNION ALL

SELECT
  'estat_job_market_2023_2025' AS table_name,
  COUNT(*) AS row_count
FROM engineer_market.estat_job_market_2023_2025;

-- 2. Row count for integrated view
SELECT
  COUNT(*) AS row_count
FROM engineer_market.v_estat_job_market;

-- Expected: 468 rows

-- 3. Row count by source file
SELECT
  source_file,
  COUNT(*) AS row_count
FROM engineer_market.v_estat_job_market
GROUP BY source_file
ORDER BY source_file;

-- Expected:
-- 2012_2022: 360
-- 2023_2025: 108

-- 4. Row count by year
SELECT
  year,
  COUNT(*) AS row_count
FROM engineer_market.v_estat_job_market
GROUP BY year
ORDER BY year;

-- Expected: 36 rows for each year from 2013 to 2025

-- 5. NULL check for integrated view
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN month IS NULL THEN 1 ELSE 0 END) AS null_month_count,
  SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS null_year_count,
  SUM(CASE WHEN occupation_name IS NULL THEN 1 ELSE 0 END) AS null_occupation_name_count,
  SUM(CASE WHEN metric_name IS NULL THEN 1 ELSE 0 END) AS null_metric_name_count,
  SUM(CASE WHEN value IS NULL THEN 1 ELSE 0 END) AS null_value_count,
  SUM(CASE WHEN unit IS NULL THEN 1 ELSE 0 END) AS null_unit_count,
  SUM(CASE WHEN source_file IS NULL THEN 1 ELSE 0 END) AS null_source_file_count
FROM engineer_market.v_estat_job_market;

-- 6. Metric names
SELECT DISTINCT
  metric_name,
  unit
FROM engineer_market.v_estat_job_market
ORDER BY metric_name;

-- Expected:
-- 新規求人 / 人
-- 有効求人 / 人
-- 有効求人倍率 / 倍

-- 7. Occupation names
SELECT DISTINCT
  occupation_name
FROM engineer_market.v_estat_job_market
ORDER BY occupation_name;

-- Expected:
-- 情報処理・通信技術者

-- 8. Row count for Tableau wide view
SELECT
  COUNT(*) AS row_count
FROM engineer_market.v_estat_job_market_monthly_wide;

-- Expected: 156 rows

-- 9. Row count by year for Tableau wide view
SELECT
  year,
  COUNT(*) AS row_count
FROM engineer_market.v_estat_job_market_monthly_wide
GROUP BY year
ORDER BY year;

-- Expected: 12 rows for each year from 2013 to 2025

-- 10. NULL check for Tableau wide view
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN month IS NULL THEN 1 ELSE 0 END) AS null_month_count,
  SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS null_year_count,
  SUM(CASE WHEN occupation_name IS NULL THEN 1 ELSE 0 END) AS null_occupation_name_count,
  SUM(CASE WHEN new_job_openings IS NULL THEN 1 ELSE 0 END) AS null_new_job_openings_count,
  SUM(CASE WHEN active_job_openings IS NULL THEN 1 ELSE 0 END) AS null_active_job_openings_count,
  SUM(CASE WHEN active_job_opening_to_applicant_ratio IS NULL THEN 1 ELSE 0 END) AS null_ratio_count
FROM engineer_market.v_estat_job_market_monthly_wide;

-- 11. Sample records for Tableau wide view
SELECT
  month,
  year,
  occupation_name,
  new_job_openings,
  active_job_openings,
  active_job_opening_to_applicant_ratio
FROM engineer_market.v_estat_job_market_monthly_wide
ORDER BY month
LIMIT 30;
