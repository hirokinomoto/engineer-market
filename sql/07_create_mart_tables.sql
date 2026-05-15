-- 07_create_mart_tables.sql
-- mart table 作成SQL
--
-- 目的:
--   Google Trends と e-Stat の staging データを、
--   Looker Studio で扱いやすい月次mart・年次martへ変換する。
--
-- 前提:
--   - stg_google_trends_adjusted_monthly 作成済み
--   - stg_estat_job_market_monthly 作成済み
--
-- 主な変更点:
--   - Google Trendsに未経験KW（beginner_query）を追加
--   - martに category_type を追加し、職種名KW / 未経験KW / e-Stat職業分類を区別できるようにする
--   - 対象期間は 2013-01-01〜2025-12-01

-- ============================================================
-- 1. monthly mart
-- ============================================================
-- 月次mart:
--   1行 = 1か月 × 1データソース × 1カテゴリ種別 × 1カテゴリ × 1指標
--
-- なぜ縦持ちにするか:
--   Google Trends と e-Stat は単位も意味も異なるため、
--   横に無理やり結合せず、data_source / category_type / category / metric_name / value 形式で統一する。
--   Looker Studio 側でデータソース・指標・KW種別をフィルタしやすくするため。

CREATE OR REPLACE TABLE `engineer-market.engineer_market.mart_engineer_market_monthly` AS

WITH google_trends AS (
  SELECT
    month,
    EXTRACT(YEAR FROM month) AS year,
    'google_trends' AS data_source,
    keyword_type AS category_type,
    keyword AS category,
    '検索関心指数' AS metric_name,
    adjusted_trend_value AS value,
    'index' AS unit
  FROM `engineer-market.engineer_market.stg_google_trends_adjusted_monthly`
  WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'
),

estat AS (
  SELECT
    month,
    EXTRACT(YEAR FROM month) AS year,
    'estat' AS data_source,
    'occupation' AS category_type,
    occupation_name AS category,
    metric_name,
    value,
    unit
  FROM `engineer-market.engineer_market.stg_estat_job_market_monthly`
  WHERE month BETWEEN DATE '2013-01-01' AND DATE '2025-12-01'
)

SELECT * FROM google_trends
UNION ALL
SELECT * FROM estat
;

-- ============================================================
-- 2. yearly mart
-- ============================================================
-- 年次mart:
--   1行 = 1年 × 1データソース × 1カテゴリ種別 × 1カテゴリ × 1指標
--
-- 年次集計方針:
--   初期版ではすべて年平均で集計する。
--
-- 理由:
--   Google Trends が月次指数のため、年次比較では平均値が自然。
--   e-Stat の新規求人は年合計で見る選択肢もあるが、
--   本プロジェクトでは検索関心指数・有効求人・有効求人倍率と見せ方を揃えるため、
--   月次値の年平均に統一する。
--
-- 補足:
--   新規求人を年間累計で評価したい場合は、別指標としてSUM集計を追加する余地がある。

CREATE OR REPLACE TABLE `engineer-market.engineer_market.mart_engineer_market_yearly` AS

SELECT
  year,
  data_source,
  category_type,
  category,
  metric_name,
  AVG(value) AS value,
  'AVG' AS aggregation_method,
  unit
FROM `engineer-market.engineer_market.mart_engineer_market_monthly`
GROUP BY
  year,
  data_source,
  category_type,
  category,
  metric_name,
  unit
;
