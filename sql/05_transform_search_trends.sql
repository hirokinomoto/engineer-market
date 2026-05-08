-- 05_transform_search_trends.sql
-- Google Trends raw → staging 変換SQL
--
-- 目的:
--   Google Trendsの横持ちrawデータを縦持ち化し、
--   アンカーKW「システムエンジニア」を使ってグループ間補正を行う。
--
-- 前提:
--   raw_google_trends_group_01 / group_02 には
--   2014-12-01〜2025-12-01 のデータが入っている可能性がある。
--   stagingでは 2015-01-01〜2025-12-01 のみを対象にする。

-- ============================================================
-- 1. raw → stg_google_trends_monthly
-- ============================================================

CREATE OR REPLACE TABLE `engineer-market.engineer_market.stg_google_trends_monthly` AS

WITH group_01 AS (
  SELECT
    month,
    keyword,
    trend_value,
    'group_01' AS source_group,
    keyword = 'システムエンジニア' AS is_anchor
  FROM `engineer-market.engineer_market.raw_google_trends_group_01`
  UNPIVOT (
    trend_value FOR keyword_code IN (
      system_engineer,
      programmer,
      it_engineer,
      web_engineer
    )
  )
  CROSS JOIN UNNEST([
    STRUCT('system_engineer' AS keyword_code_map, 'システムエンジニア' AS keyword),
    STRUCT('programmer' AS keyword_code_map, 'プログラマー' AS keyword),
    STRUCT('it_engineer' AS keyword_code_map, 'ITエンジニア' AS keyword),
    STRUCT('web_engineer' AS keyword_code_map, 'Webエンジニア' AS keyword)
  ]) AS keyword_master
  WHERE keyword_code = keyword_master.keyword_code_map
    AND month BETWEEN DATE '2015-01-01' AND DATE '2025-12-01'
),

group_02 AS (
  SELECT
    month,
    keyword,
    trend_value,
    'group_02' AS source_group,
    keyword = 'システムエンジニア' AS is_anchor
  FROM `engineer-market.engineer_market.raw_google_trends_group_02`
  UNPIVOT (
    trend_value FOR keyword_code IN (
      system_engineer,
      infrastructure_engineer,
      data_engineer,
      ai_engineer
    )
  )
  CROSS JOIN UNNEST([
    STRUCT('system_engineer' AS keyword_code_map, 'システムエンジニア' AS keyword),
    STRUCT('infrastructure_engineer' AS keyword_code_map, 'インフラエンジニア' AS keyword),
    STRUCT('data_engineer' AS keyword_code_map, 'データエンジニア' AS keyword),
    STRUCT('ai_engineer' AS keyword_code_map, 'AIエンジニア' AS keyword)
  ]) AS keyword_master
  WHERE keyword_code = keyword_master.keyword_code_map
    AND month BETWEEN DATE '2015-01-01' AND DATE '2025-12-01'
)

SELECT * FROM group_01
UNION ALL
SELECT * FROM group_02
;

-- ============================================================
-- 2. アンカーKWを使った補正
-- ============================================================
-- 考え方:
--   Google Trendsは取得グループごとに0〜100へ正規化される。
--   そのため、group_01 と group_02 を単純結合すると比較基準がずれる。
--
--   両グループに共通する「システムエンジニア」をアンカーKWとして使い、
--   group_02 を group_01 のスケールに合わせる。
--
--   補正係数 = group_01のシステムエンジニア平均値
--            / group_02のシステムエンジニア平均値

CREATE OR REPLACE TABLE `engineer-market.engineer_market.stg_google_trends_adjusted_monthly` AS

WITH anchor_avg AS (
  SELECT
    source_group,
    AVG(trend_value) AS anchor_avg_value
  FROM `engineer-market.engineer_market.stg_google_trends_monthly`
  WHERE keyword = 'システムエンジニア'
  GROUP BY source_group
),

adjustment AS (
  SELECT
    g2.anchor_avg_value AS group_02_anchor_avg,
    g1.anchor_avg_value AS group_01_anchor_avg,
    SAFE_DIVIDE(g1.anchor_avg_value, g2.anchor_avg_value) AS group_02_adjustment_factor
  FROM anchor_avg AS g1
  CROSS JOIN anchor_avg AS g2
  WHERE g1.source_group = 'group_01'
    AND g2.source_group = 'group_02'
),

adjusted AS (
  SELECT
    s.month,
    s.keyword,
    s.source_group,
    CAST(s.trend_value AS FLOAT64) AS original_trend_value,
    CASE
      WHEN s.source_group = 'group_01' THEN CAST(s.trend_value AS FLOAT64)
      WHEN s.source_group = 'group_02' THEN CAST(s.trend_value AS FLOAT64) * a.group_02_adjustment_factor
    END AS adjusted_trend_value,
    CASE
      WHEN s.source_group = 'group_01' THEN 1.0
      WHEN s.source_group = 'group_02' THEN a.group_02_adjustment_factor
    END AS adjustment_factor,
    s.is_anchor
  FROM `engineer-market.engineer_market.stg_google_trends_monthly` AS s
  CROSS JOIN adjustment AS a
)

SELECT
  month,
  keyword,
  source_group,
  original_trend_value,
  adjusted_trend_value,
  adjustment_factor,
  is_anchor
FROM adjusted
WHERE NOT (
  source_group = 'group_02'
  AND keyword = 'システムエンジニア'
)
;