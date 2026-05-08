-- 08_validation_checks.sql
-- データ検証用SQL
--
-- 目的:
--   raw / staging / mart の各層で、件数・期間・重複が想定どおりか確認する。
--
-- 注意:
--   このSQLは検証用であり、テーブル作成・更新は行わない。

-- ============================================================
-- 1. Google Trends raw checks
-- ============================================================

-- Group 1: 対象期間内の件数確認
SELECT
  'raw_google_trends_group_01' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_google_trends_group_01`
WHERE month BETWEEN DATE '2015-01-01' AND DATE '2025-12-01';

-- Group 2: 対象期間内の件数確認
SELECT
  'raw_google_trends_group_02' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_google_trends_group_02`
WHERE month BETWEEN DATE '2015-01-01' AND DATE '2025-12-01';


-- ============================================================
-- 2. Google Trends staging checks
-- ============================================================

-- 補正前staging
SELECT
  'stg_google_trends_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT keyword) AS keyword_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_monthly`;

-- 補正後staging
SELECT
  'stg_google_trends_adjusted_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT keyword) AS keyword_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`;

-- 補正後staging: KW別件数
SELECT
  keyword,
  source_group,
  COUNT(*) AS row_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
GROUP BY keyword, source_group
ORDER BY source_group, keyword;


-- ============================================================
-- 3. e-Stat raw checks
-- ============================================================

-- 2012-2022ファイル由来raw
SELECT
  'raw_estat_job_market_2012_2022' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_estat_job_market_2012_2022`;

-- 2023-2025ファイル由来raw
SELECT
  'raw_estat_job_market_2023_2025' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_estat_job_market_2023_2025`;


-- ============================================================
-- 4. e-Stat staging checks
-- ============================================================

-- e-Stat staging全体
SELECT
  'stg_estat_job_market_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`;

-- e-Stat staging: 指標別件数
SELECT
  metric_name,
  COUNT(*) AS row_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
GROUP BY metric_name
ORDER BY metric_name;


-- ============================================================
-- 5. mart checks
-- ============================================================

-- monthly mart
SELECT
  'mart_engineer_market_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT year) AS year_count,
  COUNT(DISTINCT data_source) AS data_source_count,
  COUNT(DISTINCT category) AS category_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.mart_engineer_market_monthly`;

-- yearly mart
SELECT
  'mart_engineer_market_yearly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT year) AS year_count,
  COUNT(DISTINCT data_source) AS data_source_count,
  COUNT(DISTINCT category) AS category_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(year) AS min_year,
  MAX(year) AS max_year
FROM `engineer-market.engineer_market.mart_engineer_market_yearly`;


-- ============================================================
-- 6. duplicate checks
-- ============================================================

-- Google Trends補正後stagingで、month × keyword が重複していないか
SELECT
  month,
  keyword,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
GROUP BY month, keyword
HAVING COUNT(*) > 1
ORDER BY month, keyword;

-- e-Stat stagingで、month × occupation_name × metric_name が重複していないか
SELECT
  month,
  occupation_name,
  metric_name,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
GROUP BY month, occupation_name, metric_name
HAVING COUNT(*) > 1
ORDER BY month, occupation_name, metric_name;

-- monthly martで、month × data_source × category × metric_name が重複していないか
SELECT
  month,
  data_source,
  category,
  metric_name,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.mart_engineer_market_monthly`
GROUP BY month, data_source, category, metric_name
HAVING COUNT(*) > 1
ORDER BY month, data_source, category, metric_name;

-- yearly martで、year × data_source × category × metric_name が重複していないか
SELECT
  year,
  data_source,
  category,
  metric_name,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.mart_engineer_market_yearly`
GROUP BY year, data_source, category, metric_name
HAVING COUNT(*) > 1
ORDER BY year, data_source, category, metric_name;