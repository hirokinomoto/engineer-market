# ITエンジニア市場データELTプロジェクト

## 概要

ITエンジニア職種に関する検索関心データと求人需要データを収集し、Python・BigQuery SQL・Looker Studioを用いて、データ取得から可視化までの流れを構築したポートフォリオです。

主成果物は、Looker Studioで作成した可視化レポートです。  
GitHubでは、データ取得、前処理、SQL変換、検証、ドキュメントを公開しています。

---

## 成果物

- [Looker Studio 可視化レポート](https://datastudio.google.com/s/n7OJDN4iitA)
- [詳細設計書](docs/technical_design.md)
- [テーブル定義](docs/table_definition.md)
- [BIレポート構成](docs/bi_report_summary.md)

Looker Studioでは、以下を1つのレポートとして整理しています。

- 分析の問い
- データソースとELT構成
- IT関連職種の求人需要
- 職種名への検索関心
- 未経験IT職関連KWの検索関心
- 公開データから分かること・分からないこと
- 可視化・実装で意識したこと

---

## このポートフォリオで示したこと

- 外部データをPythonで前処理し、BigQueryへ取り込む流れ
- BigQuery上で `raw → staging → mart` の層を分けたデータ設計
- Google Trendsの取得グループ差を考慮した補正
- 検証SQLによる件数、期間、重複の確認
- Looker Studioで、分析の問いから結果・限界まで伝える可視化レポートの作成

---

## 使用データ

| データ | 内容 |
|---|---|
| Google Trends | IT職種名・未経験IT職関連キーワードの検索関心指数 |
| e-Stat 職業安定業務統計 | 情報処理・通信技術者の新規求人、有効求人、有効求人倍率 |

対象期間は、2013年1月〜2025年12月です。

---

## 使用技術

- Python
- Docker
- BigQuery
- BigQuery Standard SQL
- Looker Studio
- Git / GitHub
- Markdown

---

## ディレクトリ構成

```text
data/
  raw/          # 取得元データ
  processed/    # Python前処理後のCSV

python/         # e-Stat前処理スクリプト

sql/            # BigQuery用SQL
  01_create_tables.sql
  05_transform_search_trends.sql
  06_transform_estat_job_market.sql
  07_create_mart_tables.sql
  08_validation_checks.sql

docs/           # 詳細設計・テーブル定義・BI構成メモ
```

---

## 補足

本プロジェクトでは、公開統計と検索関心データを用いて、IT関連職種全体の求人需要と検索関心の推移を確認しました。

一方で、公開統計と検索関心データだけでは、データエンジニア単体の求人件数、未経験歓迎求人の実数、年収レンジ、必須スキル、勤務地などは判断できません。

そのため、可視化レポートでは、分析結果だけでなく「このデータで分かること・分からないこと」も整理しています。
