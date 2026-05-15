-- 08_validation_checks.sql
-- データ検証用SQL
--
-- 目的:
--   raw / staging / mart の各層で、件数・期間・重複が想定どおりか確認する。
--
-- 注意:
--   このSQLは検証用であり、テーブル作成・更新は行わない。
--
-- 対象期間:
--   2013-01-01〜2025-12-01
--
-- 期待値の考え方:
--   2013〜2025年 = 13年 × 12か月 = 156か月
--   Google Trends raw:
--     group_01: 156行
--     group_02: 156行
--     beginner_it_roles: 156行
--   Google Trends staging:
--     stg_google_trends_monthly = 156か月 × 11系列 = 1716行
--     stg_google_trends_adjusted_monthly = 1716 - group_02側アンカー156行 = 1560行
--   e-Stat staging:
--     156か月 × 3指標 = 468行
--   mart:
--     monthly = Google Trends 1560行 + e-Stat 468行 = 2028行
--     yearly = Google Trends 10系列×13年 + e-Stat 3指標×13年 = 169行

-- ============================================================
-- 1. Google Trends raw checks
-- ============================================================

SELECT
  'raw_google_trends_group_01' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_google_trends_group_01`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'

UNION ALL

SELECT
  'raw_google_trends_group_02' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_google_trends_group_02`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'

UNION ALL

SELECT
  'raw_google_trends_beginner_it_roles' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_google_trends_beginner_it_roles`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'
;

-- ============================================================
-- 2. Google Trends staging checks
-- ============================================================

SELECT
  'stg_google_trends_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT keyword) AS keyword_count,
  COUNT(DISTINCT keyword_type) AS keyword_type_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_monthly`

UNION ALL

SELECT
  'stg_google_trends_adjusted_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT keyword) AS keyword_count,
  COUNT(DISTINCT keyword_type) AS keyword_type_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
;

-- 補正後staging: KW種別・取得グループ別件数
SELECT
  keyword_type,
  source_group,
  COUNT(*) AS row_count,
  COUNT(DISTINCT keyword) AS keyword_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
GROUP BY
  keyword_type,
  source_group
ORDER BY
  keyword_type,
  source_group;

-- 補正後staging: KW別件数
SELECT
  keyword_type,
  keyword,
  source_group,
  COUNT(*) AS row_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
GROUP BY
  keyword_type,
  keyword,
  source_group
ORDER BY
  keyword_type,
  source_group,
  keyword;

-- ============================================================
-- 3. e-Stat raw checks
-- ============================================================

SELECT
  'raw_estat_job_market_2012_2022' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_estat_job_market_2012_2022`

UNION ALL

SELECT
  'raw_estat_job_market_2023_2025' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.raw_estat_job_market_2023_2025`
;

-- ============================================================
-- 4. e-Stat staging checks
-- ============================================================

SELECT
  'stg_estat_job_market_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01';

-- e-Stat staging: 指標別件数
SELECT
  metric_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'
GROUP BY metric_name
ORDER BY metric_name;

-- ============================================================
-- 5. mart checks
-- ============================================================

SELECT
  'mart_engineer_market_monthly' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT month) AS month_count,
  COUNT(DISTINCT year) AS year_count,
  COUNT(DISTINCT data_source) AS data_source_count,
  COUNT(DISTINCT category_type) AS category_type_count,
  COUNT(DISTINCT category) AS category_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(month) AS min_month,
  MAX(month) AS max_month
FROM `engineer-market.engineer_market.mart_engineer_market_monthly`

UNION ALL

SELECT
  'mart_engineer_market_yearly' AS table_name,
  COUNT(*) AS row_count,
  NULL AS month_count,
  COUNT(DISTINCT year) AS year_count,
  COUNT(DISTINCT data_source) AS data_source_count,
  COUNT(DISTINCT category_type) AS category_type_count,
  COUNT(DISTINCT category) AS category_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  NULL AS min_month,
  NULL AS max_month
FROM `engineer-market.engineer_market.mart_engineer_market_yearly`
;

-- mart: データソース・カテゴリ種別別件数
SELECT
  data_source,
  category_type,
  COUNT(*) AS row_count,
  COUNT(DISTINCT category) AS category_count,
  COUNT(DISTINCT metric_name) AS metric_count,
  MIN(year) AS min_year,
  MAX(year) AS max_year
FROM `engineer-market.engineer_market.mart_engineer_market_yearly`
GROUP BY
  data_source,
  category_type
ORDER BY
  data_source,
  category_type;

-- ============================================================
-- 6. year-month completeness checks
-- ============================================================
-- 各年が12か月揃っているか確認する。
-- 結果が0件なら、対象期間内の年はすべて12か月揃っている。

SELECT
  EXTRACT(YEAR FROM month) AS year,
  COUNT(DISTINCT month) AS month_count
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
GROUP BY year
HAVING COUNT(DISTINCT month) != 12
ORDER BY year;

SELECT
  EXTRACT(YEAR FROM month) AS year,
  COUNT(DISTINCT month) AS month_count
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'
GROUP BY year
HAVING COUNT(DISTINCT month) != 12
ORDER BY year;

-- ============================================================
-- 7. duplicate checks
-- ============================================================
-- 結果が0件なら重複なし。

-- Google Trends補正後stagingで、month × keyword_type × keyword が重複していないか
SELECT
  month,
  keyword_type,
  keyword,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
GROUP BY
  month,
  keyword_type,
  keyword
HAVING COUNT(*) > 1
ORDER BY
  month,
  keyword_type,
  keyword;

-- e-Stat stagingで、month × occupation_name × metric_name が重複していないか
SELECT
  month,
  occupation_name,
  metric_name,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'
GROUP BY
  month,
  occupation_name,
  metric_name
HAVING COUNT(*) > 1
ORDER BY
  month,
  occupation_name,
  metric_name;

-- monthly martで、month × data_source × category_type × category × metric_name が重複していないか
SELECT
  month,
  data_source,
  category_type,
  category,
  metric_name,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.mart_engineer_market_monthly`
GROUP BY
  month,
  data_source,
  category_type,
  category,
  metric_name
HAVING COUNT(*) > 1
ORDER BY
  month,
  data_source,
  category_type,
  category,
  metric_name;

-- yearly martで、year × data_source × category_type × category × metric_name が重複していないか
SELECT
  year,
  data_source,
  category_type,
  category,
  metric_name,
  COUNT(*) AS row_count
FROM `engineer-market.engineer_market.mart_engineer_market_yearly`
GROUP BY
  year,
  data_source,
  category_type,
  category,
  metric_name
HAVING COUNT(*) > 1
ORDER BY
  year,
  data_source,
  category_type,
  category,
  metric_name;
