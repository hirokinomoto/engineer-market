# ELT実装サマリ

## 目的

本ドキュメントは、ITエンジニア市場データELTプロジェクトにおける実装内容を整理した補足資料です。

本プロジェクトでは、ITエンジニア職種に関する検索関心データと求人需要データを収集し、BigQuery上で `raw → staging → mart` の流れに沿って整形・検証しました。

分析結果そのものを深掘りすることよりも、以下のデータ処理フローを自分で手を動かして再現することを重視しました。

- 外部データの取得
- Pythonによる前処理
- DockerによるPython実行環境の固定化
- BigQueryへのrawデータ投入
- SQLによるstaging変換
- SQLによるmart作成
- 件数・期間・重複チェックによる検証
- Looker Studioで利用できるデータ形式への整備

---

## 使用データ

### 1. Google Trends

ITエンジニア職種に関する検索関心の推移を把握するため、Google Trendsから月次データを取得しました。

対象期間は以下です。

- 2015年1月〜2025年12月

Google Trendsは1回に比較できるキーワード数に制限があるため、2グループに分けて取得しました。

#### Group 1

| キーワード |
|---|
| システムエンジニア |
| プログラマー |
| ITエンジニア |
| Webエンジニア |

#### Group 2

| キーワード |
|---|
| システムエンジニア |
| インフラエンジニア |
| データエンジニア |
| AIエンジニア |

`システムエンジニア` は、2つの取得グループ間のスケール差を補正するためのアンカーKWとして使用しました。

---

### 2. e-Stat / 厚生労働省 職業安定業務統計

IT関連職種の求人需要を把握するため、e-Stat / 厚生労働省の職業安定業務統計を使用しました。

対象職業分類は以下です。

- 情報処理・通信技術者

対象指標は以下です。

| 指標 | 単位 |
|---|---|
| 新規求人 | 人 |
| 有効求人 | 人 |
| 有効求人倍率 | 倍 |

対象期間は以下です。

- 2015年1月〜2025年12月

使用ファイルは以下です。

| ファイル | 採用期間 |
|---|---|
| `job_market_2012_2022.xlsx` | 2015年1月〜2022年12月 |
| `job_market_2023_2025.xlsx` | 2023年1月〜2025年12月 |

2022年データは複数ファイル間で重複していましたが、数値が同一であることを確認したため、2022年は `2012_2022` 側を採用しました。

---

## ディレクトリ構成

主要な構成は以下です。

```text
engineer-market/
├── data/
│   ├── raw/
│   │   ├── estat/
│   │   │   ├── job_market_2012_2022.xlsx
│   │   │   └── job_market_2023_2025.xlsx
│   │   └── google_trends/
│   │       ├── role_group_01_general_dev.csv
│   │       └── role_group_02_infra_data_ai.csv
│   └── processed/
│       ├── estat_job_market_2012_2022.csv
│       └── estat_job_market_2023_2025.csv
├── docs/
│   ├── table_definition.md
│   ├── elt_implementation_summary.md
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

## 実装フロー

本プロジェクトでは、以下の流れでデータを整備しました。

```text
外部データ取得
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

### 1. 外部データ取得

Google Trendsとe-Statから、ITエンジニア職種に関するデータを取得しました。

Google TrendsはCSV形式、e-StatはExcel形式で取得しました。

### 2. Python前処理

e-StatのExcelは、年次列・月次列・注釈・複数シートが混在しており、BigQueryへそのまま投入しづらい構造でした。

そのため、Pythonで以下の前処理を行いました。

- 対象シートの確認
- `情報処理・通信技術者` の行を抽出
- 月次列のみを抽出
- 指標名・単位・元ファイル情報を付与
- BigQuery投入用CSVを生成

対象スクリプトは以下です。

| ファイル | 内容 |
|---|---|
| `python/inspect_estat_workbook.py` | e-Stat Excelのシート名・対象行を確認 |
| `python/extract_estat_job_market.py` | e-Stat ExcelからBigQuery投入用CSVを生成 |

生成したCSVは以下です。

| CSV | 行数 |
|---|---:|
| `estat_job_market_2012_2022.csv` | 288 |
| `estat_job_market_2023_2025.csv` | 108 |

### 3. Dockerによる実行環境の固定化

Python前処理は、ローカルPCのPython環境だけでなく、Docker上でも再実行できるようにしました。

これにより、Pythonやライブラリのバージョン差による実行環境の違いを抑え、前処理の再現性を高めています。

Docker関連ファイルは以下です。

| ファイル | 内容 |
|---|---|
| `Dockerfile` | Python前処理用の実行環境を定義 |
| `requirements.txt` | Pythonライブラリを定義 |
| `.dockerignore` | Dockerビルド時に不要なファイルを除外 |

実行例は以下です。

```powershell
docker build -t engineer-market-preprocess .

docker run --rm `
  -v "${PWD}\data:/app/data" `
  engineer-market-preprocess
```

Docker上で実行した場合も、以下の行数でCSVが生成されることを確認しました。

| CSV | 行数 |
|---|---:|
| `estat_job_market_2012_2022.csv` | 288 |
| `estat_job_market_2023_2025.csv` | 108 |

### 4. BigQuery raw層

raw層では、取得元データまたは前処理後データを、後続処理の起点として保持しました。

| テーブル | 内容 |
|---|---|
| `raw_google_trends_group_01` | Google Trends Group 1の月次データ |
| `raw_google_trends_group_02` | Google Trends Group 2の月次データ |
| `raw_estat_job_market_2012_2022` | e-Stat 2012-2022ファイル由来のCSVデータ |
| `raw_estat_job_market_2023_2025` | e-Stat 2023-2025ファイル由来のCSVデータ |

Google Trendsは取得CSVが横持ち形式だったため、rawでは横持ちのまま保持しました。

e-StatはPythonで月次データを抽出したCSVをrawとして投入しました。

### 5. BigQuery staging層

staging層では、rawデータを分析・集計しやすい形に整えました。

| テーブル | 内容 |
|---|---|
| `stg_google_trends_monthly` | Google Trends rawを縦持ち化した月次データ |
| `stg_google_trends_adjusted_monthly` | アンカーKWで補正したGoogle Trends月次データ |
| `stg_estat_job_market_monthly` | e-Statの2つのrawテーブルを統合した月次データ |

Google Trendsは、横持ちデータを以下のような縦持ち形式に変換しました。

```text
month | keyword | trend_value | source_group | is_anchor
```

また、Google Trendsは取得グループごとに0〜100で正規化されるため、両グループに含めた `システムエンジニア` をアンカーKWとして、Group 2の値をGroup 1のスケールに合わせて補正しました。

e-Statは、2つのrawテーブルを統合し、2015年1月〜2025年12月の月次データとして扱える形にしました。

### 6. BigQuery mart層

mart層では、Looker Studioで扱いやすい最終テーブルを作成しました。

| テーブル | 内容 |
|---|---|
| `mart_engineer_market_monthly` | 月次粒度の統合mart |
| `mart_engineer_market_yearly` | 年次粒度の統合mart |

martでは、Google Trendsとe-Statを以下の共通形式に統一しました。

```text
month / year / data_source / category / metric_name / value / unit
```

この形式にすることで、BI側でデータソース、カテゴリ、指標を切り替えやすくしています。

---

## SQLファイル

BigQuery上では、以下のSQLを作成しました。

| SQLファイル | 内容 |
|---|---|
| `sql/01_create_tables.sql` | データセット・テーブル作成 |
| `sql/05_transform_search_trends.sql` | Google Trends rawをstagingへ変換 |
| `sql/06_transform_estat_job_market.sql` | e-Stat rawをstagingへ変換 |
| `sql/07_create_mart_tables.sql` | monthly / yearly martを作成 |
| `sql/08_validation_checks.sql` | 件数・期間・重複チェック |

---

## 検証内容

作成したデータに対して、以下を確認しました。

- 行数
- 月数・年数
- 期間の最小・最大
- 指標数
- カテゴリ数
- 重複有無

主な検証結果は以下です。

| テーブル | 行数 | 期間 |
|---|---:|---|
| `stg_google_trends_monthly` | 1056 | 2015-01〜2025-12 |
| `stg_google_trends_adjusted_monthly` | 924 | 2015-01〜2025-12 |
| `stg_estat_job_market_monthly` | 396 | 2015-01〜2025-12 |
| `mart_engineer_market_monthly` | 1320 | 2015-01〜2025-12 |
| `mart_engineer_market_yearly` | 110 | 2015〜2025 |

以下の粒度で重複がないことを確認しました。

| 対象 | 粒度 | 結果 |
|---|---|---|
| Google Trends補正後staging | month × keyword | 重複なし |
| e-Stat staging | month × occupation_name × metric_name | 重複なし |
| monthly mart | month × data_source × category × metric_name | 重複なし |
| yearly mart | year × data_source × category × metric_name | 重複なし |

---

## Looker Studio連携

BigQueryの `mart_engineer_market_yearly` をLooker Studioへ接続し、年次推移レポートを作成しました。

レポート構成の詳細は、以下に整理しています。

- [BIレポート構成メモ](bi_report_summary.md)

---

## 実装上のポイント

本プロジェクトでは、以下の点を重視しました。

- rawデータを残し、後続処理で整形する構成にしたこと
- Google Trendsとe-Statを共通形式のmartに統合したこと
- Python前処理をDockerでも再実行できるようにしたこと
- 検証SQLで件数・期間・重複を確認できるようにしたこと
- Looker Studioで利用しやすい年次martを作成したこと

---

## 今後の改善候補

必要に応じて、以下を改善します。

1. 月次martを使った詳細確認用ページを追加する
2. GitHub Actions等を用いた検証SQL実行の自動化
