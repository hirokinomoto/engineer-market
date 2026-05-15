-- 06_transform_estat_job_market.sql
-- e-Stat raw → staging 変換SQL
--
-- 目的:
--   e-Statの2つのrawテーブルを統合し、
--   2013年1月〜2025年12月の月次求人需要データとして整形する。
--
-- 対象:
--   職業分類: 情報処理・通信技術者
--   指標:
--     - 新規求人
--     - 有効求人
--     - 有効求人倍率
--
-- 補足:
--   2012年は1月・2月が収録されていないため、
--   年次比較の整合性を優先して2013年以降を対象とする。

CREATE OR REPLACE TABLE `engineer-market.engineer_market.stg_estat_job_market_monthly` AS

WITH unioned AS (
  SELECT
    month,
    occupation_name,
    metric_name,
    value,
    unit,
    source_file
  FROM `engineer-market.engineer_market.raw_estat_job_market_2012_2022`
  WHERE month BETWEEN DATE '2013-01-01' AND DATE '2022-12-01'

  UNION ALL

  SELECT
    month,
    occupation_name,
    metric_name,
    value,
    unit,
    source_file
  FROM `engineer-market.engineer_market.raw_estat_job_market_2023_2025`
  WHERE month BETWEEN DATE '2023-01-01' AND DATE '2025-12-01'
),

filtered AS (
  SELECT
    month,
    occupation_name,
    metric_name,
    value,
    unit,
    source_file
  FROM unioned
  WHERE occupation_name = '情報処理・通信技術者'
    AND metric_name IN ('新規求人', '有効求人', '有効求人倍率')
)

SELECT
  month,
  occupation_name,
  metric_name,
  value,
  unit,
  source_file
FROM filtered
;
