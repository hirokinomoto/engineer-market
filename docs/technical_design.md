# 詳細設計書

## 目的

本ドキュメントは、ITエンジニア市場データELTプロジェクトにおける設計・実装内容を整理した詳細資料です。

READMEではプロジェクトの全体像と成果物への導線を短く示し、本ドキュメントでは使用データ、ELT構成、Python前処理、SQL変換処理、検証内容を整理します。

---

## 使用データ

### Google Trends

ITエンジニア職種に関する検索関心の推移を把握するため、Google Trendsから月次データを取得しました。

- 対象期間：2013年1月〜2025年12月
- 地域：日本
- 検索タイプ：ウェブ検索
- 粒度：月次

Google Trendsは、取得グループごとに0〜100で正規化されます。  
そのため、職種名キーワードは2グループに分けて取得し、両グループに共通して含めた `システムエンジニア` をアンカーKWとして使用しました。

また、未経験からIT職を目指す層の検索関心を確認するため、未経験IT職関連KWを別グループとして取得しました。

#### 職種名KW Group 1

| キーワード |
|---|
| システムエンジニア |
| プログラマー |
| ITエンジニア |
| Webエンジニア |

#### 職種名KW Group 2

| キーワード |
|---|
| システムエンジニア |
| インフラエンジニア |
| データエンジニア |
| AIエンジニア |

`システムエンジニア` は、2つの職種名KW取得グループ間のスケール差を補正するためのアンカーKWとして使用しました。

#### 未経験IT職関連KW

| キーワード |
|---|
| IT 未経験 |
| エンジニア 未経験 |
| プログラマー 未経験 |

未経験IT職関連KWは、職種名KWとは目的が異なるため、`keyword_type = beginner_query` として区別しています。

### e-Stat / 厚生労働省 職業安定業務統計

求人需要の推移を確認するため、e-Stat / 厚生労働省の職業安定業務統計を使用しました。

- 対象職業分類：情報処理・通信技術者
- 対象期間：2013年1月〜2025年12月
- 粒度：月次

対象指標は以下です。

| 指標 | 単位 |
|---|---|
| 新規求人 | 人 |
| 有効求人 | 人 |
| 有効求人倍率 | 倍 |

使用ファイルは以下です。

| ファイル | 採用期間 |
|---|---|
| `job_market_2012_2022.xlsx` | 2013年1月〜2022年12月 |
| `job_market_2023_2025.xlsx` | 2023年1月〜2025年12月 |

2012年は1月・2月が収録されていないため、年次比較の整合性を優先して2013年以降を対象としました。

2022年データは複数ファイル間で重複していましたが、数値が同一であることを確認したため、2022年は `2012_2022` 側を採用しました。

---

## ディレクトリ構成

```text
engineer-market/
├── data/
│   ├── raw/
│   │   ├── estat/
│   │   │   ├── job_market_2012_2022.xlsx
│   │   │   └── job_market_2023_2025.xlsx
│   │   └── google_trends/
│   │       ├── trends_role_group_01_pg_it_web_2013_2025.csv
│   │       ├── trends_role_group_02_infra_data_ai_2013_2025.csv
│   │       └── trends_beginner_it_roles_2013_2025.csv
│   └── processed/
│       ├── estat_job_market_2012_2022.csv
│       └── estat_job_market_2023_2025.csv
├── docs/
│   ├── technical_design.md
│   ├── table_definition.md
│   └── bi_report_summary.md
├── python/
│   ├── inspect_estat_workbook.py
│   └── extract_estat_job_market.py
├── sql/
│   ├── 01_create_tables.sql
│   ├── 05_transform_search_trends.sql
│   ├── 06_transform_estat_job_market.sql
│   ├── 07_create_mart_tables.sql
│   └── 08_validation_checks.sql
├── Dockerfile
├── requirements.txt
├── .dockerignore
└── README.md
```

---

## ELT構成

本プロジェクトでは、BigQuery上で以下の3層構成を採用しました。

```text
raw
  ↓
staging
  ↓
mart
```

### raw層

取得元データ、または前処理後データを、後続処理の起点として保持する層です。

| テーブル | 内容 |
|---|---|
| `raw_google_trends_group_01` | 職種名KW Group 1の月次データ |
| `raw_google_trends_group_02` | 職種名KW Group 2の月次データ |
| `raw_google_trends_beginner_it_roles` | 未経験IT職関連KWの月次データ |
| `raw_estat_job_market_2012_2022` | e-Stat 2012-2022ファイル由来のCSVデータ |
| `raw_estat_job_market_2023_2025` | e-Stat 2023-2025ファイル由来のCSVデータ |

Google Trendsは取得CSVが横持ち形式だったため、rawでは横持ちのまま保持しました。

e-StatはExcelの構造が複雑だったため、Pythonで必要範囲をCSV化したうえでBigQueryへ投入しました。

### staging層

rawデータを分析・集計しやすい形に整える層です。

| テーブル | 内容 |
|---|---|
| `stg_google_trends_monthly` | Google Trends rawを縦持ち化した月次データ |
| `stg_google_trends_adjusted_monthly` | アンカーKWで補正したGoogle Trends月次データ |
| `stg_estat_job_market_monthly` | e-Statの2つのrawテーブルを統合した月次データ |

Google Trendsでは、横持ちデータを以下のような縦持ち形式に変換しました。

```text
month | keyword_type | keyword | trend_value | source_group | is_anchor
```

`keyword_type` によって、通常の職種名KWと未経験IT職関連KWを区別しています。

| keyword_type | 内容 |
|---|---|
| `role_name` | 職種名KW |
| `beginner_query` | 未経験IT職関連KW |

Google Trendsは取得グループごとに0〜100で正規化されるため、両グループに含めた `システムエンジニア` をアンカーKWとして補正しました。

補正後の `stg_google_trends_adjusted_monthly` では、重複するGroup 2側のアンカーKWを除外し、職種名KWと未経験IT職関連KWを統一的に扱える形にしています。

### mart層

Looker Studioで扱いやすい形に整えた最終テーブルです。

| テーブル | 内容 |
|---|---|
| `mart_engineer_market_monthly` | 月次粒度の統合mart |
| `mart_engineer_market_yearly` | 年次粒度の統合mart |

martでは、Google Trendsとe-Statを以下の共通形式に統一しました。

```text
month / year / data_source / category_type / category / metric_name / value / unit
```

`category_type` によって、職種名KW、未経験IT職関連KW、e-Stat職業分類を区別しています。

| category_type | 内容 |
|---|---|
| `role_name` | 職種名KW |
| `beginner_query` | 未経験IT職関連KW |
| `occupation` | e-Stat職業分類 |

この形式にすることで、BI側でデータソース、カテゴリ種別、カテゴリ、指標を切り替えやすくしています。

---

## Python前処理

e-StatのExcelは、年次列・月次列・注釈・複数シートが混在しており、BigQueryへそのまま投入しづらい構造でした。

そのため、Pythonで以下の処理を行いました。

1. Excelファイルを読み込む
2. 対象シートを抽出する
3. `情報処理・通信技術者` の行のみ取得する
4. 月次列のみ抽出する
5. 2013年1月〜2025年12月の対象期間に絞る
6. 指標名・単位・元ファイル情報を付与する
7. BigQuery投入用CSVとして出力する

対象スクリプトは以下です。

| ファイル | 内容 |
|---|---|
| `python/inspect_estat_workbook.py` | e-Stat Excelのシート名・対象行を確認 |
| `python/extract_estat_job_market.py` | e-Stat ExcelからBigQuery投入用CSVを生成 |

作成したCSVは以下です。

| CSV | 行数 |
|---|---:|
| `estat_job_market_2012_2022.csv` | 360 |
| `estat_job_market_2023_2025.csv` | 108 |

### Dockerでの実行

Python前処理は、ローカルPCのPython環境だけでなく、Docker上でも再実行できるようにしました。

これにより、Pythonやライブラリのバージョン差による実行環境の違いを抑え、前処理の再現性を高めています。

実行例は以下です。

```powershell
docker build -t engineer-market-preprocess .

docker run --rm `
  -v "${PWD}\data:/app/data" `
  engineer-market-preprocess
```

Docker上で実行した場合も、以下の行数でCSVが生成される想定です。

| CSV | 行数 |
|---|---:|
| `estat_job_market_2012_2022.csv` | 360 |
| `estat_job_market_2023_2025.csv` | 108 |

---

## SQL変換処理

BigQuery上では、以下のSQLを作成しました。

| SQLファイル | 内容 |
|---|---|
| `sql/01_create_tables.sql` | データセット・テーブル作成 |
| `sql/05_transform_search_trends.sql` | Google Trends rawをstagingへ変換 |
| `sql/06_transform_estat_job_market.sql` | e-Stat rawをstagingへ変換 |
| `sql/07_create_mart_tables.sql` | monthly / yearly martを作成 |
| `sql/08_validation_checks.sql` | 件数・期間・重複チェック |

### `05_transform_search_trends.sql`

Google Trendsの3つのrawテーブルを縦持ち化し、以下の2つのstagingテーブルを作成します。

| テーブル | 内容 |
|---|---|
| `stg_google_trends_monthly` | 職種名KW・未経験IT職関連KWを縦持ち化した月次データ |
| `stg_google_trends_adjusted_monthly` | 職種名KWのグループ間補正を行い、未経験IT職関連KWも含めた補正後データ |

職種名KW Group 2については、Group 1との比較基準を揃えるため、共通アンカーKWである `システムエンジニア` を使って補正しています。

### `06_transform_estat_job_market.sql`

e-Statの2つのrawテーブルを統合し、2013年1月〜2025年12月の月次求人需要データを作成します。

### `07_create_mart_tables.sql`

Google Trendsとe-Statのstagingデータを統合し、Looker Studioで扱いやすい月次mart・年次martを作成します。

年次martでは、各月の値を年平均で集計しています。

```text
Google Trends：月次検索関心指数の年平均
新規求人：月次値の年平均
有効求人：月次値の年平均
有効求人倍率：月次値の年平均
```

新規求人は年間累計として見る方法もありますが、本プロジェクトでは指標間の見せ方を揃えるため、年平均で統一しています。

---

## 検証内容

作成したデータに対して、以下を確認しました。

- 行数
- 月数・年数
- 期間の最小・最大
- 指標数
- カテゴリ数
- カテゴリ種別数
- 重複有無

主な検証結果は以下です。

| テーブル | 行数 | 期間 |
|---|---:|---|
| `stg_google_trends_monthly` | 1716 | 2013-01〜2025-12 |
| `stg_google_trends_adjusted_monthly` | 1560 | 2013-01〜2025-12 |
| `stg_estat_job_market_monthly` | 468 | 2013-01〜2025-12 |
| `mart_engineer_market_monthly` | 2028 | 2013-01〜2025-12 |
| `mart_engineer_market_yearly` | 169 | 2013〜2025 |

Google Trendsの件数内訳は以下です。

| 区分 | 行数 | キーワード数 | 期間 |
|---|---:|---:|---|
| `beginner_query / beginner_it_roles` | 468 | 3 | 2013-01〜2025-12 |
| `role_name / group_01` | 624 | 4 | 2013-01〜2025-12 |
| `role_name / group_02` | 468 | 3 | 2013-01〜2025-12 |

`role_name / group_02` が3キーワードになっているのは、重複アンカーKWである `システムエンジニア` を補正後データから除外しているためです。

e-Statの件数内訳は以下です。

| 指標 | 行数 | 月数 | 期間 |
|---|---:|---:|---|
| 新規求人 | 156 | 156 | 2013-01〜2025-12 |
| 有効求人 | 156 | 156 | 2013-01〜2025-12 |
| 有効求人倍率 | 156 | 156 | 2013-01〜2025-12 |

martの年次データの内訳は以下です。

| data_source | category_type | 行数 | カテゴリ数 | 指標数 | 期間 |
|---|---|---:|---:|---:|---|
| `estat` | `occupation` | 39 | 1 | 3 | 2013〜2025 |
| `google_trends` | `beginner_query` | 39 | 3 | 1 | 2013〜2025 |
| `google_trends` | `role_name` | 91 | 7 | 1 | 2013〜2025 |

以下の粒度で重複がないことを確認しました。

| 対象 | 粒度 | 結果 |
|---|---|---|
| Google Trends補正後staging | month × keyword_type × keyword | 重複なし |
| e-Stat staging | month × occupation_name × metric_name | 重複なし |
| monthly mart | month × data_source × category_type × category × metric_name | 重複なし |
| yearly mart | year × data_source × category_type × category × metric_name | 重複なし |

---

## Looker Studio連携

BigQueryの `mart_engineer_market_yearly` をLooker Studioへ接続し、ITエンジニア市場データELT可視化レポートを作成しました。

レポートでは、単にグラフを並べるだけでなく、以下の流れで確認できる提示型ダッシュボードとして構成しています。

1. 目的
2. 分析の問い
3. データとELT構成
4. IT関連職種の求人需要
5. 職種名への検索関心
6. 未経験IT職関連KWの検索関心
7. 公開データから分かること・分からないこと
8. 可視化・実装で意識したこと

レポート構成の詳細は、以下に整理しています。

- [BIレポート構成](bi_report_summary.md)

---

## 成果物

| 種別 | ファイル |
|---|---|
| Python前処理 | `python/inspect_estat_workbook.py`, `python/extract_estat_job_market.py` |
| Docker実行環境 | `Dockerfile`, `requirements.txt`, `.dockerignore` |
| BigQuery SQL | `sql/01_create_tables.sql`, `sql/05_transform_search_trends.sql`, `sql/06_transform_estat_job_market.sql`, `sql/07_create_mart_tables.sql`, `sql/08_validation_checks.sql` |
| テーブル定義 | `docs/table_definition.md` |
| 詳細設計書 | `docs/technical_design.md` |
| BIレポート構成 | `docs/bi_report_summary.md` |

---

## 補足ドキュメント

関連する補足資料は以下です。

- [テーブル定義](table_definition.md)
- [BIレポート構成](bi_report_summary.md)
