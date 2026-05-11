# ITエンジニア市場データELTプロジェクト

## 概要

本プロジェクトは、ITエンジニア職種に関する検索関心データと求人需要データを収集し、Python・BigQuery SQL・Looker Studioを用いて、データ取得から可視化までの一連の流れを構築したポートフォリオです。

分析結果そのものを深掘りすることよりも、データエンジニア業務で必要となる以下の流れを、自分で手を動かして再現することを重視しました。

- 外部データの収集
- Pythonによる前処理
- DockerによるPython実行環境の固定化
- BigQuery上での `raw → staging → mart` 構成
- SQLによるデータ変換・統合
- 検証SQLによる品質確認
- Looker Studioによる可視化

データ分析サービスの開発・運用において必要となる、データパイプライン構築、分析基盤設計、ダッシュボード提供までの流れを意識して作成しました。

---

## 作成背景

データエンジニア職を目指すにあたり、SQLやPythonを個別に学習するだけでなく、実務でデータがどのように扱われるのかを一連の流れとして理解する必要があると考えました。

求人情報や業務内容を確認すると、データエンジニアには、取得元データを扱いやすい形に整え、分析基盤上で再利用しやすいテーブルを設計し、BIツールで可視化できる状態までつなげる力が求められると感じました。

そこで本プロジェクトでは、ITエンジニア市場を題材に、Google Trendsとe-Statの2種類の外部データを使用し、データ形式や粒度が異なる複数データソースをBigQuery上で統一的に扱える形へ整備しました。

---

## 実務を想定した実装範囲

本プロジェクトでは、単一のツール操作ではなく、外部データの取得から前処理、BigQueryでのELT構成、検証SQL、Looker Studioでの可視化までを一連の流れとして実装しました。

| 実務で求められる要素 | 本プロジェクトで実装した内容 |
|---|---|
| データパイプラインの構築 | Google Trends / e-Stat → Python前処理 → BigQuery → Looker Studio の流れを構築 |
| 分析基盤の設計・開発 | BigQuery上で `raw → staging → mart` の3層構成を設計 |
| SQLによるデータ処理 | 横持ちデータの縦持ち化、複数テーブル統合、年次mart作成、検証SQLを実装 |
| Pythonによる基礎的なデータ処理 | e-Stat Excelから必要行・必要列を抽出し、BigQuery投入用CSVを生成 |
| Dockerの基礎的な利用 | Python前処理をDocker上で再実行できる環境を作成 |
| 可視化ダッシュボード | Looker Studioで年次推移レポートを作成 |
| テスト・品質確認 | 件数、期間、指標数、重複有無を確認する検証SQLを作成 |
| Git/GitHubの利用 | ブランチ作成、コミット、Pull Request、マージの流れで管理 |
| ドキュメント化 | 実装サマリ、テーブル定義、BI構成メモをdocs配下に整理 |

---

## 使用データ

### Google Trends

ITエンジニア職種に関する検索関心の推移を把握するため、Google Trendsから月次データを取得しました。

- 対象期間：2015年1月〜2025年12月
- 地域：日本
- 検索タイプ：ウェブ検索

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

### e-Stat / 厚生労働省 職業安定業務統計

求人需要の推移を確認するため、e-Stat / 厚生労働省の職業安定業務統計を使用しました。

- 対象職業分類：情報処理・通信技術者
- 対象期間：2015年1月〜2025年12月

対象指標は以下です。

| 指標 | 単位 |
|---|---|
| 新規求人 | 人 |
| 有効求人 | 人 |
| 有効求人倍率 | 倍 |

使用ファイルは以下です。

| ファイル | 採用期間 |
|---|---|
| `job_market_2012_2022.xlsx` | 2015年1月〜2022年12月 |
| `job_market_2023_2025.xlsx` | 2023年1月〜2025年12月 |

2022年データは複数ファイル間で重複していましたが、数値が同一であることを確認したため、2022年は `2012_2022` 側を採用しました。

---

## 技術スタック

| 区分 | 使用技術 |
|---|---|
| データ取得 | Google Trends, e-Stat |
| 前処理 | Python, openpyxl, csv |
| 実行環境 | Docker |
| データ基盤 | BigQuery |
| SQL | BigQuery Standard SQL |
| BI | Looker Studio |
| バージョン管理 | Git, GitHub |
| ドキュメント | Markdown |

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

取得元データをなるべく元の形に近い状態で保持する層です。

| テーブル | 内容 |
|---|---|
| `raw_google_trends_group_01` | Google Trends Group 1の月次データ |
| `raw_google_trends_group_02` | Google Trends Group 2の月次データ |
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
month | keyword | trend_value | source_group | is_anchor
```

これにより、キーワード追加やBI上でのフィルタリングに対応しやすい形にしています。

また、Google Trendsは取得グループごとに0〜100で正規化されるため、両グループに含めた `システムエンジニア` をアンカーKWとして補正しました。

### mart層

Looker Studioで扱いやすい形に整えた最終テーブルです。

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

## Python前処理

e-StatのExcelは、年次列・月次列・注釈・複数シートが混在しており、BigQueryへそのまま投入しづらい構造でした。

そのため、Pythonで以下の処理を行いました。

1. Excelファイルを読み込む
2. 対象シートを抽出する
3. `情報処理・通信技術者` の行のみ取得する
4. 月次列のみ抽出する
5. 指標名・単位・元ファイル情報を付与する
6. BigQuery投入用CSVとして出力する

対象スクリプトは以下です。

| ファイル | 内容 |
|---|---|
| `python/inspect_estat_workbook.py` | e-Stat Excelのシート名・対象行を確認 |
| `python/extract_estat_job_market.py` | e-Stat ExcelからBigQuery投入用CSVを生成 |

作成したCSVは以下です。

| CSV | 行数 |
|---|---:|
| `estat_job_market_2012_2022.csv` | 288 |
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

Docker上で実行した場合も、以下の行数でCSVが生成されることを確認しました。

| CSV | 行数 |
|---|---:|
| `estat_job_market_2012_2022.csv` | 288 |
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

---

## Looker Studioレポート

BigQueryの `mart_engineer_market_yearly` をLooker Studioへ接続し、以下のグラフを作成しました。

[ITエンジニア市場データELT 可視化レポート](https://datastudio.google.com/s/n7OJDN4iitA)

| グラフ | 内容 |
|---|---|
| 職種別の検索関心指数 推移 | Google Trendsの検索関心指数を職種別に可視化 |
| 情報処理・通信技術者の求人件数 推移 | e-Statの新規求人・有効求人を可視化 |
| 情報処理・通信技術者の有効求人倍率 推移 | e-Statの有効求人倍率を可視化 |

`新規求人`・`有効求人` は単位が「人」であるため同じグラフに表示し、`有効求人倍率` は単位が「倍」であるため別グラフに分けました。

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

## 成果物

| 種別 | ファイル |
|---|---|
| Python前処理 | `python/inspect_estat_workbook.py`, `python/extract_estat_job_market.py` |
| Docker実行環境 | `Dockerfile`, `requirements.txt`, `.dockerignore` |
| BigQuery SQL | `sql/01_create_tables.sql`, `sql/05_transform_search_trends.sql`, `sql/06_transform_estat_job_market.sql`, `sql/07_create_mart_tables.sql`, `sql/08_validation_checks.sql` |
| テーブル定義 | `docs/table_definition.md` |
| ELT実装サマリ | `docs/elt_implementation_summary.md` |
| BIレポート構成 | `docs/bi_report_summary.md` |

---

## 詳細ドキュメント

詳細は以下のドキュメントに整理しています。

- [ELT実装サマリ](docs/elt_implementation_summary.md)
- [テーブル定義](docs/table_definition.md)
- [BIレポート構成](docs/bi_report_summary.md)

READMEでは全体像を示し、詳細な実装内容はdocs配下の補助ドキュメントに分けています。

---

## 今後の改善

今後の改善候補は以下です。

- 月次martを使った詳細確認ページの追加
- GitHub Actions等を用いた検証SQL実行の自動化

---

## 補足

本プロジェクトは、実務未経験からデータエンジニア職を目指すにあたり、データ取得、前処理、分析基盤設計、SQL変換、品質確認、BI可視化までの流れを一通り実装することを目的に作成しました。

分析結果の主張よりも、データを扱いやすい形に整備し、再利用可能なテーブルとして提供するプロセスを重視しています。
