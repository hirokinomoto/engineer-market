-- 01_create_tables.sql
-- ITエンジニア市場データELTプロジェクト
-- BigQuery用テーブル作成SQL
--
-- 目的:
--   raw → staging → mart の各層に必要なテーブルを作成する。
--
-- 実行前提:
--   - BigQueryプロジェクトIDは自分の環境に合わせて置換する
--   - 例: `your_project_id.engineer_market.table_name`
--
-- 置換対象:
--   your_project_id

-- ============================================================
-- 0. データセット作成
-- ============================================================

CREATE SCHEMA IF NOT EXISTS `your_project_id.engineer_market`
OPTIONS (
  location = "asia-northeast1"
);

-- なぜデータセットを分けるか:
--   このポートフォリオ用のテーブルを1つのデータセットにまとめることで、
--   raw / staging / mart の関係を管理しやすくするため。


-- ============================================================
-- 1. raw tables
-- ============================================================
-- raw層:
--   取得元データをなるべく元の形に近い状態で保持する層。
--   Google Trendsは取得CSV単位でテーブルを分ける。
--   e-StatはExcelから必要範囲をCSV化したうえで取り込む想定。

-- ------------------------------------------------------------
-- 1-1. Google Trends Group 1
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.raw_google_trends_group_01` (
  month DATE OPTIONS(description = "月初日"),
  system_engineer INT64 OPTIONS(description = "システムエンジニアの検索関心指数"),
  it_engineer INT64 OPTIONS(description = "ITエンジニアの検索関心指数"),
  programmer INT64 OPTIONS(description = "プログラマーの検索関心指数"),
  web_engineer INT64 OPTIONS(description = "Webエンジニアの検索関心指数")
)
OPTIONS (
  description = "Google Trends Group 1 raw table: システムエンジニア、ITエンジニア、プログラマー、Webエンジニア"
);

-- なぜ横持ちのままrawにするか:
--   Google Trends CSVが横持ち形式で出力されるため。
--   rawでは元データの形を保ち、縦持ち変換はstagingで行う。


-- ------------------------------------------------------------
-- 1-2. Google Trends Group 2
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.raw_google_trends_group_02` (
  month DATE OPTIONS(description = "月初日"),
  system_engineer INT64 OPTIONS(description = "システムエンジニアの検索関心指数"),
  infrastructure_engineer INT64 OPTIONS(description = "インフラエンジニアの検索関心指数"),
  data_engineer INT64 OPTIONS(description = "データエンジニアの検索関心指数"),
  ai_engineer INT64 OPTIONS(description = "AIエンジニアの検索関心指数")
)
OPTIONS (
  description = "Google Trends Group 2 raw table: システムエンジニア、インフラエンジニア、データエンジニア、AIエンジニア"
);

-- なぜGroup 1 / Group 2を分けるか:
--   Google Trendsは1回に比較できるKW数に上限があり、取得CSVが2つに分かれるため。
--   raw層では取得元ファイル単位を維持する。


-- ------------------------------------------------------------
-- 1-3. e-Stat 2012-2022
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.raw_estat_job_market_2012_2022` (
  month DATE OPTIONS(description = "月初日"),
  occupation_name STRING OPTIONS(description = "職業分類名"),
  metric_name STRING OPTIONS(description = "指標名: 新規求人 / 有効求人 / 有効求人倍率"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位: 人 / 倍"),
  source_file STRING OPTIONS(description = "元ファイル識別子")
)
OPTIONS (
  description = "e-Stat 職業安定業務統計 2012-2022ファイル由来のraw table。使用対象は2015年1月〜2022年12月。"
);

-- なぜe-Stat rawは縦持ちにするか:
--   e-Stat Excelは年次列・月次列・注釈などが混在しており、そのままではBigQueryで扱いづらい。
--   そのため、必要な職業分類・指標・月次列のみをCSV化して取り込む。
--   ただし、集計や補正はまだ行わず、最低限の抽出に留める。


-- ------------------------------------------------------------
-- 1-4. e-Stat 2023-2025
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.raw_estat_job_market_2023_2025` (
  month DATE OPTIONS(description = "月初日"),
  occupation_name STRING OPTIONS(description = "職業分類名"),
  metric_name STRING OPTIONS(description = "指標名: 新規求人 / 有効求人 / 有効求人倍率"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位: 人 / 倍"),
  source_file STRING OPTIONS(description = "元ファイル識別子")
)
OPTIONS (
  description = "e-Stat 職業安定業務統計 2023-2025ファイル由来のraw table。2022年重複分は除外し、2023年1月〜2025年12月を使用する。"
);

-- 2022年を除外する理由:
--   2012-2022ファイルと2023-2025ファイルで2022年データが重複しているため。
--   数値は同じであることを確認済みのため、2022年は2012-2022ファイル側を採用する。


-- ============================================================
-- 2. master tables
-- ============================================================
-- master層:
--   KWや指標の分類・表示順・単位などを管理する補助テーブル。
--   SQL内に条件を直接書きすぎないようにするために用意する。

-- ------------------------------------------------------------
-- 2-1. Google Trends KW master
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.mst_google_trends_keyword` (
  keyword STRING OPTIONS(description = "Google Trendsで使用する検索KW"),
  role_category STRING OPTIONS(description = "職種カテゴリ"),
  keyword_type STRING OPTIONS(description = "KW種別。初期版ではrole_name"),
  display_order INT64 OPTIONS(description = "可視化時の表示順"),
  is_anchor BOOL OPTIONS(description = "アンカーKWかどうか")
)
OPTIONS (
  description = "Google Trends検索KWの分類・表示順・アンカー判定を管理するマスタ"
);

-- ------------------------------------------------------------
-- 2-2. e-Stat metric master
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.mst_estat_metric` (
  metric_name STRING OPTIONS(description = "e-Stat指標名"),
  metric_label STRING OPTIONS(description = "表示用指標名"),
  unit STRING OPTIONS(description = "単位"),
  aggregation_method STRING OPTIONS(description = "年次集計方法: AVG / SUM")
)
OPTIONS (
  description = "e-Stat指標の単位・表示名・集計方法を管理するマスタ"
);

-- なぜマスタを作るか:
--   KWの表示順や指標の単位・集計方法をSQLに直接埋め込みすぎると、
--   後で変更しづらくなるため。
--   マスタで管理することで、分類や表示名を一元管理できる。


-- ============================================================
-- 3. staging tables
-- ============================================================
-- staging層:
--   rawデータを分析・集計しやすい形に整形する層。
--   横持ち → 縦持ち変換、期間フィルタ、重複除外、補正などを行う。

-- ------------------------------------------------------------
-- 3-1. Google Trends monthly staging
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.stg_google_trends_monthly` (
  month DATE OPTIONS(description = "月初日"),
  keyword STRING OPTIONS(description = "検索KW"),
  trend_value INT64 OPTIONS(description = "Google Trends検索関心指数"),
  source_group STRING OPTIONS(description = "取得グループ: group_01 / group_02"),
  is_anchor BOOL OPTIONS(description = "アンカーKWかどうか")
)
OPTIONS (
  description = "Google Trends rawデータを縦持ちに変換した月次staging table"
);

-- なぜ縦持ちにするか:
--   KWごとの集計・年次平均・Looker Studioでのグラフ化がしやすくなるため。
--   KWが列のままだと、KW追加時にSQLや可視化設定が複雑になる。


-- ------------------------------------------------------------
-- 3-2. Google Trends adjusted monthly staging
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.stg_google_trends_adjusted_monthly` (
  month DATE OPTIONS(description = "月初日"),
  keyword STRING OPTIONS(description = "検索KW"),
  source_group STRING OPTIONS(description = "取得グループ: group_01 / group_02"),
  original_trend_value FLOAT64 OPTIONS(description = "補正前の検索関心指数"),
  adjusted_trend_value FLOAT64 OPTIONS(description = "補正後の検索関心指数"),
  adjustment_factor FLOAT64 OPTIONS(description = "アンカーKWを使った補正係数"),
  is_anchor BOOL OPTIONS(description = "アンカーKWかどうか")
)
OPTIONS (
  description = "Google Trendsのグループ間スケール差をアンカーKWで補正した月次staging table"
);

-- なぜ補正テーブルを分けるか:
--   補正前と補正後の値を両方残すことで、変換内容を確認できるようにするため。
--   Google Trendsはグループごとに0〜100へ正規化されるため、別グループ間比較には補正が必要。


-- ------------------------------------------------------------
-- 3-3. e-Stat monthly staging
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.stg_estat_job_market_monthly` (
  month DATE OPTIONS(description = "月初日"),
  occupation_name STRING OPTIONS(description = "職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位"),
  source_file STRING OPTIONS(description = "元ファイル識別子")
)
OPTIONS (
  description = "e-Stat rawデータを統合し、重複期間を除外した月次staging table"
);

-- なぜe-Statも縦持ちにするか:
--   複数指標をmetric_name/value形式で扱うことで、指標追加に強い構造にするため。
--   新規求人・有効求人・有効求人倍率を同じ形で扱える。


-- ============================================================
-- 4. mart tables
-- ============================================================
-- mart層:
--   Looker Studioで使いやすい形にした最終テーブル。
--   月次詳細用と年次可視化用を分ける。

-- ------------------------------------------------------------
-- 4-1. monthly mart
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.mart_engineer_market_monthly` (
  month DATE OPTIONS(description = "月初日"),
  year INT64 OPTIONS(description = "年"),
  data_source STRING OPTIONS(description = "データソース: google_trends / estat"),
  category STRING OPTIONS(description = "KW名または職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "指標値"),
  unit STRING OPTIONS(description = "単位: index / 人 / 倍")
)
OPTIONS (
  description = "Google Trendsとe-Statを月次粒度で比較可能な形に統合したmart table"
);

-- なぜ月次martを作るか:
--   詳細確認や特定イベント前後の変化を見るため。
--   raw/stagingよりもLooker Studioで扱いやすい形にする。


-- ------------------------------------------------------------
-- 4-2. yearly mart
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `your_project_id.engineer_market.mart_engineer_market_yearly` (
  year INT64 OPTIONS(description = "年"),
  data_source STRING OPTIONS(description = "データソース: google_trends / estat"),
  category STRING OPTIONS(description = "KW名または職業分類名"),
  metric_name STRING OPTIONS(description = "指標名"),
  value FLOAT64 OPTIONS(description = "年次集計値"),
  aggregation_method STRING OPTIONS(description = "集計方法: AVG / SUM"),
  unit STRING OPTIONS(description = "単位: index / 人 / 倍")
)
OPTIONS (
  description = "2015〜2025年の長期推移を可視化するための年次mart table"
);

-- なぜ年次martを作るか:
--   2015〜2025年の月次データは132か月分あり、長期傾向を見るには細かすぎるため。
--   年次平均にすることで、Looker Studioで長期推移を見やすくする。


-- ============================================================
-- 5. 参考: 初期データ投入用INSERTは別SQLで作成予定
-- ============================================================
-- マスタテーブルへの初期データ投入や、rawデータのロード手順は
-- 02_load_raw_data.sql 以降で作成する。
