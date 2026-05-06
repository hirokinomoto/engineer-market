# table_definition.md（作業メモ）

## 目的

本ドキュメントは、ITエンジニア市場データELTプロジェクトにおける BigQuery テーブル設計の作業メモです。

公開用ドキュメントではなく、SQL実装前に以下を整理するために作成します。

- raw / staging / mart の役割
- 各テーブルの粒度
- カラム定義
- なぜその構造にするか
- 後続SQLで何を実装するか

---

## 全体方針

本プロジェクトでは、以下の流れでデータを扱います。

```text
CSV / Excel
  ↓
BigQuery raw
  ↓
BigQuery staging
  ↓
BigQuery mart
  ↓
Looker Studio
```

### なぜ raw → staging → mart に分けるか

ELTでは、元データをすぐに分析用へ加工するのではなく、段階を分けて管理します。

| 層 | 役割 | このプロジェクトでの意味 |
|---|---|---|
| raw | 取得元データをなるべくそのまま保持する | Google Trends CSV / e-Stat CSVを元に戻せる形で保存する |
| staging | 分析しやすい形に整形する | 横持ちデータを縦持ち化し、日付・指標名・値を整理する |
| mart | 可視化・比較に使う最終形にする | Looker Studioで扱いやすい月次・年次テーブルを作る |

この構造にすることで、加工ミスがあった場合も raw に戻って再処理できます。  
また、staging と mart を分けることで、「整形」と「可視化用集計」の責任範囲を分けられます。

---

## BigQuery データセット

### データセット名

```text
engineer_market
```

### 採用理由

プロジェクトのテーマが「ITエンジニア市場データ」であるため、短く意味が伝わる名前として `engineer_market` を使用します。

---

## raw テーブル設計

raw層では、取得元ファイル単位をできるだけ維持します。

理由は、元CSVや元Excelから取り込んだ状態を残すことで、後から staging の変換ロジックを見直しやすくするためです。

---

## 1. raw_google_trends_group_01

### 役割

Google Trends の Group 1 CSVを格納する raw テーブルです。

### 元ファイル

```text
システム、IT、プログラマー、Web.csv
```

### 対象KW

```text
システムエンジニア
ITエンジニア
プログラマー
Webエンジニア
```

### 粒度

```text
1行 = 1か月
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| system_engineer | INT64 | システムエンジニアの検索関心指数 |
| it_engineer | INT64 | ITエンジニアの検索関心指数 |
| programmer | INT64 | プログラマーの検索関心指数 |
| web_engineer | INT64 | Webエンジニアの検索関心指数 |

### なぜ横持ちのまま raw に入れるか

Google TrendsのCSVは、1列目が月、2列目以降がKW別の検索関心指数になっています。

raw層では、CSVの形を大きく変えずに保持します。  
縦持ちへの変換は staging 層で行います。

---

## 2. raw_google_trends_group_02

### 役割

Google Trends の Group 2 CSVを格納する raw テーブルです。

### 元ファイル

```text
システム、インフラ、データ、AI.csv
```

### 対象KW

```text
システムエンジニア
インフラエンジニア
データエンジニア
AIエンジニア
```

### 粒度

```text
1行 = 1か月
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| system_engineer | INT64 | システムエンジニアの検索関心指数 |
| infrastructure_engineer | INT64 | インフラエンジニアの検索関心指数 |
| data_engineer | INT64 | データエンジニアの検索関心指数 |
| ai_engineer | INT64 | AIエンジニアの検索関心指数 |

### なぜ Group 1 と Group 2 を分けるか

Google Trendsは1回に比較できるKW数に上限があり、今回の7KWを一括で取得できません。  
そのため、取得CSVは2つに分かれています。

raw層では、どの値がどの取得グループ由来かを明確にするため、2つのrawテーブルとして管理します。

---

## 3. raw_estat_job_market_2012_2022

### 役割

e-Stat / 厚生労働省「職業安定業務統計」のうち、2012〜2022年ファイルから抽出したデータを格納する raw テーブルです。

### 元ファイル

```text
一般職業紹介状況（職業安定業務統計）2012-2022.xlsx
```

### 使用対象期間

```text
2015年1月〜2022年12月
```

### 対象職業分類

```text
情報処理・通信技術者
```

### 対象指標

```text
新規求人
有効求人
有効求人倍率
```

### 粒度

```text
1行 = 1か月 × 1指標
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| occupation_name | STRING | 職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 指標値 |
| unit | STRING | 単位 |
| source_file | STRING | 2012_2022 |

### なぜ raw の時点で縦持ちにするか

e-StatのExcelは、タイトル行・年次列・月次列・注釈などが混在しており、そのままBigQueryに投入すると扱いにくくなります。

そのため、BigQuery投入前に必要な3指標・対象職業分類・月次列だけを抽出し、CSV化してから取り込みます。

ただし、この段階では集計や補正は行わず、対象範囲を切り出す最低限の前処理に留めます。

---

## 4. raw_estat_job_market_2023_2025

### 役割

e-Stat / 厚生労働省「職業安定業務統計」のうち、2023〜2025年ファイルから抽出したデータを格納する raw テーブルです。

### 元ファイル

```text
一般職業紹介状況（職業安定業務統計）2023-2025.xlsx
```

### 使用対象期間

```text
2023年1月〜2025年12月
```

### 対象職業分類

```text
情報処理・通信技術者
```

### 対象指標

```text
新規求人
有効求人
有効求人倍率
```

### 粒度

```text
1行 = 1か月 × 1指標
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| occupation_name | STRING | 職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 指標値 |
| unit | STRING | 単位 |
| source_file | STRING | 2023_2025 |

### 2022年データを除外する理由

2012-2022ファイルと2023-2025ファイルには、2022年データが重複して含まれています。

確認したところ重複している2022年の数値は同じだったため、重複取込を避けるために、2022年は2012-2022ファイル側を採用します。

そのため、2023-2025ファイル側では2022年データを使用しません。

---

# staging テーブル設計

staging層では、rawデータを分析・集計しやすい形に整えます。

主な処理は以下です。

- 横持ちから縦持ちへの変換
- 対象期間のフィルタ
- データソース名・グループ名の付与
- 指標名・単位の整理
- アンカーKW判定
- 重複除外

---

## 5. stg_google_trends_monthly

### 役割

Google Trendsの2つのrawテーブルを縦持ちに変換し、月次検索関心データとして統合します。

### 粒度

```text
1行 = 1か月 × 1KW × 1取得グループ
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| keyword | STRING | 検索KW |
| trend_value | INT64 | Google Trendsの検索関心指数 |
| source_group | STRING | group_01 / group_02 |
| is_anchor | BOOL | アンカーKWかどうか |

### なぜこの形にするか

Google Trendsのrawデータは横持ちですが、比較・集計を行うには縦持ちの方が扱いやすいです。

縦持ちにすることで、以下が簡単になります。

- KW別の年平均集計
- KWマスタとのJOIN
- アンカーKWによるグループ間補正
- Looker Studioでの職種別折れ線グラフ作成

---

## 6. stg_google_trends_adjusted_monthly

### 役割

`stg_google_trends_monthly` に対して、アンカーKWを使ったグループ間補正を行ったテーブルです。

### 粒度

```text
1行 = 1か月 × 1KW
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| keyword | STRING | 検索KW |
| source_group | STRING | group_01 / group_02 |
| original_trend_value | FLOAT64 | 補正前の検索関心指数 |
| adjusted_trend_value | FLOAT64 | 補正後の検索関心指数 |
| adjustment_factor | FLOAT64 | 補正係数 |
| is_anchor | BOOL | アンカーKWかどうか |

### なぜ補正テーブルを分けるか

Google Trendsは取得グループごとに0〜100へ正規化されます。

今回のデータはGroup 1とGroup 2に分かれているため、そのまま結合すると、グループ間の比較基準がずれます。

そのため、共通して含まれる `システムエンジニア` をアンカーKWとして使い、Group 2をGroup 1基準に補正します。

補正前の値と補正後の値を同じテーブルに残すことで、どのような変換を行ったか確認できます。

---

## 7. stg_estat_job_market_monthly

### 役割

e-Statの2つのrawテーブルを統合し、月次求人需要データとして整形します。

### 粒度

```text
1行 = 1か月 × 1職業分類 × 1指標
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| occupation_name | STRING | 職業分類名 |
| metric_name | STRING | 新規求人 / 有効求人 / 有効求人倍率 |
| value | FLOAT64 | 指標値 |
| unit | STRING | 人 / 倍 |
| source_file | STRING | 2012_2022 / 2023_2025 |

### なぜこの形にするか

e-Statは複数指標を扱うため、`metric_name` と `value` に分けた縦持ち形式にします。

これにより、後から別の指標を追加する場合でも、テーブル構造を大きく変更せずに済みます。

また、2012-2022ファイルと2023-2025ファイルの重複期間を除外したうえで統合することで、2015〜2025年の一貫した月次データとして扱えます。

---

# mart テーブル設計

mart層では、Looker Studioで使いやすい形に集計します。

本プロジェクトでは、月次データを保持するmartと、基本可視化用の年次martを分けます。

---

## 8. mart_engineer_market_monthly

### 役割

Google Trendsとe-Statの月次データを、データソース・カテゴリ・指標別に比較可能な形でまとめます。

### 粒度

```text
1行 = 1か月 × 1データソース × 1カテゴリ × 1指標
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| year | INT64 | 年 |
| data_source | STRING | google_trends / estat |
| category | STRING | KW名または職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 指標値 |
| unit | STRING | index / 人 / 倍 |

### なぜこの形にするか

Google Trendsとe-Statは意味の異なるデータです。

そのため、無理に横並びの1行にまとめるのではなく、`data_source` と `metric_name` を持たせた縦持ちの比較用テーブルにします。

この形にすると、Looker Studioでデータソース別・指標別にフィルタしやすくなります。

---

## 9. mart_engineer_market_yearly

### 役割

2015〜2025年の長期推移を見やすくするため、月次martを年次集計したテーブルです。

### 粒度

```text
1行 = 1年 × 1データソース × 1カテゴリ × 1指標
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| year | INT64 | 年 |
| data_source | STRING | google_trends / estat |
| category | STRING | KW名または職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 年次集計値 |
| aggregation_method | STRING | AVG / SUM |
| unit | STRING | index / 人 / 倍 |

### 年次集計の方針

初期版では、Google Trendsとe-Statの比較・可視化のしやすさを優先し、すべて年平均で集計します。

```text
Google Trends：月次検索関心指数の年平均
新規求人：月次値の年平均
有効求人：月次値の年平均
有効求人倍率：月次値の年平均
```

新規求人は年間累計として見る方法もありますが、初期版では年平均で統一します。

### なぜ年次martを作るか

2015〜2025年の長期推移を月次のまま見ると、132か月分になり、傾向が見づらくなります。

そのため、基本の可視化では年次martを使い、特定年やイベント前後の詳細確認では月次martを使います。

---

# マスタテーブル案

初期版では必須ではありませんが、SQL実装を整理するために、以下のマスタテーブルを作る案があります。

---

## 10. mst_google_trends_keyword

### 役割

Google Trendsで使用するKWの分類・表示順・代表カテゴリを管理します。

### 粒度

```text
1行 = 1KW
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| keyword | STRING | 検索KW |
| role_category | STRING | 職種カテゴリ |
| keyword_type | STRING | role_name |
| display_order | INT64 | 表示順 |
| is_anchor | BOOL | アンカーKWかどうか |

### なぜ作るか

KW名をSQL内に直接書きすぎると、後からKWを変更したときに修正箇所が増えます。

マスタ化しておくことで、KW分類や表示順を管理しやすくなります。

---

## 11. mst_estat_metric

### 役割

e-Statで使用する指標名と単位を管理します。

### 粒度

```text
1行 = 1指標
```

### カラム案

| カラム名 | 型 | 内容 |
|---|---|---|
| metric_name | STRING | 指標名 |
| metric_label | STRING | 表示名 |
| unit | STRING | 人 / 倍 |
| aggregation_method | STRING | AVG / SUM |

### なぜ作るか

e-Statでは複数の指標を扱うため、指標ごとの単位や集計方法をマスタ管理すると、mart作成時のSQLが分かりやすくなります。

---

# 次に作成するSQL

この設計を前提に、次は以下のSQLファイルを作成します。

```text
sql/
├── 01_create_tables.sql
├── 02_load_raw_data.sql
├── 03_create_staging_tables.sql
├── 04_transform_job_stats.sql
├── 05_transform_search_trends.sql
├── 06_create_mart_tables.sql
└── 07_validation_checks.sql
```

## 最初に作るSQL

最初は以下から着手します。

```text
01_create_tables.sql
```

このSQLでは、BigQuery上に raw / staging / mart / master 系のテーブル定義を作成します。

---

# 現時点の未確定事項

以下は、実データ確認後に調整します。

- e-Stat ExcelからCSV化する具体的な範囲
- e-Stat CSVの列名
- Google Trends CSVの実際の列名
- BigQuery投入時の列名変換ルール
- 新規求人を年平均だけで扱うか、年合計も追加するか
- Google Trendsの補正係数を期間平均で出すか、月別で出すか
