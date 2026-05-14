# ITエンジニア市場データELTプロジェクト

## 概要

ITエンジニア職種に関する検索関心データと求人需要データを収集し、Python・BigQuery SQL・Looker Studioを用いて、データ取得から可視化までの一連の流れを構築したポートフォリオです。

分析結果を深掘りすることよりも、データエンジニア業務で必要となる以下の流れを、自分で手を動かして再現することを重視しました。

```text
外部データ取得
  ↓
Python前処理
  ↓
BigQuery raw / staging / mart
  ↓
検証SQL
  ↓
Looker Studio可視化
```

---

## 作成背景

データエンジニア職を目指すにあたり、SQLやPythonを個別に学習するだけでなく、実務でデータがどのように扱われるのかを一連の流れとして理解する必要があると考えました。

本プロジェクトでは、Google Trendsとe-Statの2種類の外部データを使い、形式や粒度が異なるデータをBigQuery上で統一的に扱える形へ整備しました。

---

## 実務を想定した実装範囲

| 実務で求められる要素 | 本プロジェクトで実装した内容 |
|---|---|
| データパイプライン構築 | Google Trends / e-Stat → Python前処理 → BigQuery → Looker Studio の流れを構築 |
| 分析基盤設計 | BigQuery上で `raw → staging → mart` の3層構成を設計 |
| SQLによるデータ処理 | 横持ちデータの縦持ち化、複数テーブル統合、年次mart作成、検証SQLを実装 |
| Pythonによる前処理 | e-Stat Excelから必要行・必要列を抽出し、BigQuery投入用CSVを生成 |
| Dockerによる再現性確保 | Python前処理をDocker上でも再実行できる環境を作成 |
| BI可視化 | Looker Studioで年次推移レポートを作成 |

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

## Looker Studioレポート

BigQueryの `mart_engineer_market_yearly` をLooker Studioへ接続し、検索関心と求人需要の年次推移を可視化しました。

[ITエンジニア市場データELT 可視化レポート](https://datastudio.google.com/s/n7OJDN4iitA)

作成したグラフは以下です。

| グラフ | 内容 |
|---|---|
| 職種別の検索関心指数 推移 | Google Trendsの検索関心指数を職種別に可視化 |
| 情報処理・通信技術者の求人件数 推移 | e-Statの新規求人・有効求人を可視化 |
| 情報処理・通信技術者の有効求人倍率 推移 | e-Statの有効求人倍率を可視化 |

---

## 詳細ドキュメント

詳細な設計・実装内容は以下に整理しています。

- [詳細設計書](docs/technical_design.md)
- [テーブル定義](docs/table_definition.md)
- [BIレポート構成](docs/bi_report_summary.md)

---

## 今後の改善

今後の改善候補は以下です。

- 月次martを使った詳細確認ページの追加
- GitHub Actions等を用いた検証SQL実行の自動化

---

## 補足

本プロジェクトは、実務未経験からデータエンジニア職を目指すにあたり、データ取得、前処理、分析基盤設計、SQL変換、品質確認、BI可視化までの流れを一通り実装することを目的に作成しました。

分析結果の主張よりも、データを扱いやすい形に整備し、再利用可能なテーブルとして提供するプロセスを重視しています。
