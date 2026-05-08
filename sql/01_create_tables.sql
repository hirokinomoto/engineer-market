-- 01_create_tables.sql
-- ITエンジニア市場データELTプロジェクト
-- BigQuery用テーブル作成SQL
--
-- 実行前提:
--   - BigQueryプロジェクトID: engineer-market
--   - データセット名: engineer_market

CREATE SCHEMA IF NOT EXISTS `engineer-market.engineer_market`
OPTIONS (
  location = "asia-northeast1"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.raw_google_trends_group_01` (
  month DATE OPTIONS(description = "月初日"),
  system_engineer INT64 OPTIONS(description = "システムエンジニアの検索関心指数"),
  programmer INT64 OPTIONS(description = "プログラマーの検索関心指数"),
  it_engineer INT64 OPTIONS(description = "ITエンジニアの検索関心指数"),
  web_engineer INT64 OPTIONS(description = "Webエンジニアの検索関心指数")
)
OPTIONS (
  description = "Google Trends Group 1 raw table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.raw_google_trends_group_02` (
  month DATE OPTIONS(description = "月初日"),
  system_engineer INT64 OPTIONS(description = "システムエンジニアの検索関心指数"),
  infrastructure_engineer INT64 OPTIONS(description = "インフラエンジニアの検索関心指数"),
  data_engineer INT64 OPTIONS(description = "データエンジニアの検索関心指数"),
  ai_engineer INT64 OPTIONS(description = "AIエンジニアの検索関心指数")
)
OPTIONS (
  description = "Google Trends Group 2 raw table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.raw_estat_job_market_2012_2022` (
  month DATE OPTIONS(description = "月初日"),
  occupation_name STRING OPTIONS(description = "職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位"),
  source_file STRING OPTIONS(description = "元ファイル識別子")
)
OPTIONS (
  description = "e-Stat 職業安定業務統計 2012-2022 raw table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.raw_estat_job_market_2023_2025` (
  month DATE OPTIONS(description = "月初日"),
  occupation_name STRING OPTIONS(description = "職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位"),
  source_file STRING OPTIONS(description = "元ファイル識別子")
)
OPTIONS (
  description = "e-Stat 職業安定業務統計 2023-2025 raw table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.mst_google_trends_keyword` (
  keyword STRING OPTIONS(description = "Google Trendsで使用する検索KW"),
  role_category STRING OPTIONS(description = "職種カテゴリ"),
  keyword_type STRING OPTIONS(description = "KW種別"),
  display_order INT64 OPTIONS(description = "表示順"),
  is_anchor BOOL OPTIONS(description = "アンカーKWかどうか")
)
OPTIONS (
  description = "Google Trends検索KWマスタ"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.mst_estat_metric` (
  metric_name STRING OPTIONS(description = "e-Stat指標名"),
  metric_label STRING OPTIONS(description = "表示用指標名"),
  unit STRING OPTIONS(description = "単位"),
  aggregation_method STRING OPTIONS(description = "年次集計方法")
)
OPTIONS (
  description = "e-Stat指標マスタ"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.stg_google_trends_monthly` (
  month DATE OPTIONS(description = "月初日"),
  keyword STRING OPTIONS(description = "検索KW"),
  trend_value INT64 OPTIONS(description = "Google Trends検索関心指数"),
  source_group STRING OPTIONS(description = "取得グループ"),
  is_anchor BOOL OPTIONS(description = "アンカーKWかどうか")
)
OPTIONS (
  description = "Google Trends monthly staging table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.stg_google_trends_adjusted_monthly` (
  month DATE OPTIONS(description = "月初日"),
  keyword STRING OPTIONS(description = "検索KW"),
  source_group STRING OPTIONS(description = "取得グループ"),
  original_trend_value FLOAT64 OPTIONS(description = "補正前の検索関心指数"),
  adjusted_trend_value FLOAT64 OPTIONS(description = "補正後の検索関心指数"),
  adjustment_factor FLOAT64 OPTIONS(description = "補正係数"),
  is_anchor BOOL OPTIONS(description = "アンカーKWかどうか")
)
OPTIONS (
  description = "Google Trends adjusted monthly staging table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.stg_estat_job_market_monthly` (
  month DATE OPTIONS(description = "月初日"),
  occupation_name STRING OPTIONS(description = "職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位"),
  source_file STRING OPTIONS(description = "元ファイル識別子")
)
OPTIONS (
  description = "e-Stat monthly staging table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.mart_engineer_market_monthly` (
  month DATE OPTIONS(description = "月初日"),
  year INT64 OPTIONS(description = "年"),
  data_source STRING OPTIONS(description = "データソース"),
  category STRING OPTIONS(description = "KW名または職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位")
)
OPTIONS (
  description = "Monthly mart table"
);

CREATE OR REPLACE TABLE `engineer-market.engineer_market.mart_engineer_market_yearly` (
  year INT64 OPTIONS(description = "年"),
  data_source STRING OPTIONS(description = "データソース"),
  category STRING OPTIONS(description = "KW名または職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "年次集計値"),
  aggregation_method STRING OPTIONS(description = "集計方法"),
  unit STRING OPTIONS(description = "単位")
)
OPTIONS (
  description = "Yearly mart table"
);
