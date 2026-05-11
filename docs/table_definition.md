# テーブル定義

## 目的

本ドキュメントは、ITエンジニア市場データELTプロジェクトにおけるBigQueryテーブル設計を整理した補足資料です。

本プロジェクトでは、Google Trendsとe-StatのデータをBigQuery上で `raw → staging → mart` の流れに沿って整備し、Looker Studioで可視化できる形にしました。

このドキュメントでは、各テーブルの役割、粒度、主なカラム、設計意図を整理します。

---

## 全体方針

本プロジェクトでは、以下の流れでデータを扱います。

```text
CSV / Excel
  ↓
Python前処理
  ↓
BigQuery raw
  ↓
BigQuery staging
  ↓
BigQuery mart
  ↓
Looker Studio
```

### raw → staging → mart に分ける理由

元データをすぐに分析用へ加工するのではなく、段階を分けて管理します。

| 層 | 役割 | このプロジェクトでの意味 |
|---|---|---|
| raw | 取得元データ、または前処理後データを後続処理の起点として保持する | Google Trends CSV / e-Stat前処理CSVをBigQueryに投入する |
| staging | 分析・集計しやすい形に整形する | 横持ちデータの縦持ち化、指標名・単位・対象期間の整理を行う |
| mart | 可視化・比較に使う最終形にする | Looker Studioで扱いやすい月次・年次テーブルを作る |

この構造にすることで、加工ミスがあった場合もrawに戻って再処理できます。  
また、stagingとmartを分けることで、「整形」と「可視化用集計」の責任範囲を分けられます。

---

## BigQuery データセット

### データセット名

```text
engineer_market
```

### 採用理由

プロジェクトのテーマが「ITエンジニア市場データ」であるため、短く意味が伝わる名前として `engineer_market` を使用しました。

---

# raw テーブル

raw層では、取得元ファイル単位をできるだけ維持します。

Google Trendsは取得CSVが横持ち形式のため、rawでは横持ちのまま保持します。  
e-Statは元Excelの構造が複雑なため、Pythonで必要範囲を抽出したCSVをrawとして投入します。

---

## 1. raw_google_trends_group_01

### 役割

Google TrendsのGroup 1 CSVを格納するrawテーブルです。

### 元ファイル

```text
role_group_01_general_dev.csv
```

### 対象キーワード

```text
システムエンジニア
プログラマー
ITエンジニア
Webエンジニア
```

### 粒度

```text
1行 = 1か月
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| system_engineer | INT64 | システムエンジニアの検索関心指数 |
| programmer | INT64 | プログラマーの検索関心指数 |
| it_engineer | INT64 | ITエンジニアの検索関心指数 |
| web_engineer | INT64 | Webエンジニアの検索関心指数 |

### 設計意図

Google TrendsのCSVは、1列目が月、2列目以降がキーワード別の検索関心指数になっています。

raw層では、CSVの形を大きく変えずに保持します。  
縦持ちへの変換はstaging層で行います。

---

## 2. raw_google_trends_group_02

### 役割

Google TrendsのGroup 2 CSVを格納するrawテーブルです。

### 元ファイル

```text
role_group_02_infra_data_ai.csv
```

### 対象キーワード

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

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| system_engineer | INT64 | システムエンジニアの検索関心指数 |
| infrastructure_engineer | INT64 | インフラエンジニアの検索関心指数 |
| data_engineer | INT64 | データエンジニアの検索関心指数 |
| ai_engineer | INT64 | AIエンジニアの検索関心指数 |

### 設計意図

Google Trendsは1回に比較できるキーワード数に上限があります。  
そのため、取得CSVは2つのグループに分けています。

raw層では、どの値がどの取得グループ由来かを明確にするため、2つのrawテーブルとして管理します。

---

## 3. raw_estat_job_market_2012_2022

### 役割

e-Stat / 厚生労働省「職業安定業務統計」のうち、2012〜2022年ファイルから抽出したデータを格納するrawテーブルです。

### 元ファイル

```text
job_market_2012_2022.xlsx
```

### BigQuery投入用CSV

```text
data/processed/estat_job_market_2012_2022.csv
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
1行 = 1か月 × 1職業分類 × 1指標
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| occupation_name | STRING | 職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 指標値 |
| unit | STRING | 単位 |
| source_file | STRING | 2012_2022 |

### 設計意図

e-StatのExcelは、タイトル行・年次列・月次列・注釈などが混在しており、そのままBigQueryに投入すると扱いにくくなります。

そのため、BigQuery投入前にPythonで必要な3指標・対象職業分類・月次列だけを抽出し、CSV化してから取り込みます。

---

## 4. raw_estat_job_market_2023_2025

### 役割

e-Stat / 厚生労働省「職業安定業務統計」のうち、2023〜2025年ファイルから抽出したデータを格納するrawテーブルです。

### 元ファイル

```text
job_market_2023_2025.xlsx
```

### BigQuery投入用CSV

```text
data/processed/estat_job_market_2023_2025.csv
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
1行 = 1か月 × 1職業分類 × 1指標
```

### カラム

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

確認したところ重複している2022年の数値は同一だったため、重複取込を避けるために2022年は2012-2022ファイル側を採用します。

---

# staging テーブル

staging層では、rawデータを分析・集計しやすい形に整えます。

主な処理は以下です。

- 横持ちから縦持ちへの変換
- 対象期間のフィルタ
- データソース名・グループ名の付与
- 指標名・単位の整理
- アンカーKW判定
- Google Trendsのグループ間補正
- e-Statデータの統合

---

## 5. stg_google_trends_monthly

### 役割

Google Trendsの2つのrawテーブルを縦持ちに変換し、月次検索関心データとして統合します。

### 粒度

```text
1行 = 1か月 × 1キーワード × 1取得グループ
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| keyword | STRING | 検索キーワード |
| trend_value | INT64 | Google Trendsの検索関心指数 |
| source_group | STRING | group_01 / group_02 |
| is_anchor | BOOL | アンカーKWかどうか |

### 設計意図

Google Trendsのrawデータは横持ちですが、比較・集計を行うには縦持ちの方が扱いやすいです。

縦持ちにすることで、以下を扱いやすくしています。

- キーワード別の年平均集計
- アンカーKWによるグループ間補正
- Looker Studioでの職種別折れ線グラフ作成

---

## 6. stg_google_trends_adjusted_monthly

### 役割

`stg_google_trends_monthly` に対して、アンカーKWを使ったグループ間補正を行ったテーブルです。

### 粒度

```text
1行 = 1か月 × 1キーワード
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| keyword | STRING | 検索キーワード |
| source_group | STRING | group_01 / group_02 |
| original_trend_value | FLOAT64 | 補正前の検索関心指数 |
| adjusted_trend_value | FLOAT64 | 補正後の検索関心指数 |
| adjustment_factor | FLOAT64 | 補正係数 |
| is_anchor | BOOL | アンカーKWかどうか |

### 設計意図

Google Trendsは取得グループごとに0〜100へ正規化されます。

今回のデータはGroup 1とGroup 2に分かれているため、そのまま結合するとグループ間の比較基準がずれます。

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

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| occupation_name | STRING | 職業分類名 |
| metric_name | STRING | 新規求人 / 有効求人 / 有効求人倍率 |
| value | FLOAT64 | 指標値 |
| unit | STRING | 人 / 倍 |
| source_file | STRING | 2012_2022 / 2023_2025 |

### 設計意図

e-Statは複数指標を扱うため、`metric_name` と `value` に分けた縦持ち形式にします。

これにより、別の指標を追加する場合でも、テーブル構造を大きく変更せずに済みます。

また、2012-2022ファイルと2023-2025ファイルの重複期間を除外したうえで統合することで、2015〜2025年の一貫した月次データとして扱えます。

---

# mart テーブル

mart層では、Looker Studioで使いやすい形に集計します。

本プロジェクトでは、月次データを保持するmartと、基本可視化用の年次martを分けています。

---

## 8. mart_engineer_market_monthly

### 役割

Google Trendsとe-Statの月次データを、データソース・カテゴリ・指標別に比較可能な形でまとめます。

### 粒度

```text
1行 = 1か月 × 1データソース × 1カテゴリ × 1指標
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| month | DATE | 月初日 |
| year | INT64 | 年 |
| data_source | STRING | google_trends / estat |
| category | STRING | キーワード名または職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 指標値 |
| unit | STRING | index / 人 / 倍 |

### 設計意図

Google Trendsとe-Statは意味の異なるデータです。

そのため、無理に横並びの1行にまとめるのではなく、`data_source` と `metric_name` を持たせた縦持ちの比較用テーブルにしています。

この形にすると、Looker Studioでデータソース別・指標別にフィルタしやすくなります。

---

## 9. mart_engineer_market_yearly

### 役割

2015〜2025年の長期推移を見やすくするため、月次martを年次集計したテーブルです。

### 粒度

```text
1行 = 1年 × 1データソース × 1カテゴリ × 1指標
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| year | INT64 | 年 |
| data_source | STRING | google_trends / estat |
| category | STRING | キーワード名または職業分類名 |
| metric_name | STRING | 指標名 |
| value | FLOAT64 | 年次集計値 |
| aggregation_method | STRING | AVG |
| unit | STRING | index / 人 / 倍 |

### 年次集計の方針

Google Trendsとe-Statの比較・可視化のしやすさを優先し、年次集計は平均値で統一しています。

```text
Google Trends：月次検索関心指数の年平均
新規求人：月次値の年平均
有効求人：月次値の年平均
有効求人倍率：月次値の年平均
```

新規求人は年間累計として見る方法もありますが、本プロジェクトでは指標間の見せ方を揃えるため、年平均で統一しています。

### 設計意図

2015〜2025年の長期推移を月次のまま見ると132か月分になり、傾向が見づらくなります。

そのため、基本の可視化では年次martを使い、特定年やイベント前後の詳細確認では月次martを使う想定にしています。

---

# マスタテーブル

## 10. mst_google_trends_keyword

### 役割

Google Trendsで使用するキーワードの分類・表示順・アンカー判定を管理します。

### 粒度

```text
1行 = 1キーワード
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| keyword | STRING | 検索キーワード |
| role_category | STRING | 職種カテゴリ |
| keyword_type | STRING | role_name |
| display_order | INT64 | 表示順 |
| is_anchor | BOOL | アンカーKWかどうか |

### 設計意図

キーワード名や表示順をSQL内に直接書きすぎると、後から変更したときに修正箇所が増えます。

マスタ化しておくことで、キーワード分類や表示順を管理しやすくしています。

---

## 11. mst_estat_metric

### 役割

e-Statで使用する指標名と単位を管理します。

### 粒度

```text
1行 = 1指標
```

### カラム

| カラム名 | 型 | 内容 |
|---|---|---|
| metric_name | STRING | 指標名 |
| metric_label | STRING | 表示名 |
| unit | STRING | 人 / 倍 |
| aggregation_method | STRING | AVG |

### 設計意図

e-Statでは複数の指標を扱うため、指標ごとの単位や集計方法をマスタ管理しています。

これにより、mart作成時に指標の意味や単位を整理しやすくしています。

---

## 実装済みSQL

この設計に基づき、以下のSQLを作成しています。

```text
sql/
├── 01_create_tables.sql
├── 05_transform_search_trends.sql
├── 06_transform_estat_job_market.sql
├── 07_create_mart_tables.sql
└── 08_validation_checks.sql
```

| SQLファイル | 内容 |
|---|---|
| `01_create_tables.sql` | データセット・テーブル作成 |
| `05_transform_search_trends.sql` | Google Trends rawをstagingへ変換 |
| `06_transform_estat_job_market.sql` | e-Stat rawをstagingへ変換 |
| `07_create_mart_tables.sql` | monthly / yearly martを作成 |
| `08_validation_checks.sql` | 件数・期間・重複チェック |

---

## 補足

このテーブル構成では、Google Trendsとe-Statを無理に同じ意味の指標として扱うのではなく、`data_source`・`category`・`metric_name`・`unit` を持たせて、BI上で切り替えながら確認できる形にしています。

これにより、データソースや指標が増えた場合でも、martの基本構造を大きく変えずに拡張しやすくしています。
