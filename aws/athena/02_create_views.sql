-- Amazon Athena views for Tableau connection

CREATE OR REPLACE VIEW engineer_market.v_estat_job_market AS
SELECT
  CAST(month AS date) AS month,
  year(CAST(month AS date)) AS year,
  occupation_name,
  metric_name,
  value,
  unit,
  source_file
FROM engineer_market.estat_job_market_2012_2022

UNION ALL

SELECT
  CAST(month AS date) AS month,
  year(CAST(month AS date)) AS year,
  occupation_name,
  metric_name,
  value,
  unit,
  source_file
FROM engineer_market.estat_job_market_2023_2025;

CREATE OR REPLACE VIEW engineer_market.v_estat_job_market_monthly_wide AS
SELECT
  month,
  year,
  occupation_name,

  MAX(CASE
    WHEN metric_name = '新規求人' THEN value
  END) AS new_job_openings,

  MAX(CASE
    WHEN metric_name = '有効求人' THEN value
  END) AS active_job_openings,

  MAX(CASE
    WHEN metric_name = '有効求人倍率' THEN value
  END) AS active_job_opening_to_applicant_ratio

FROM engineer_market.v_estat_job_market
GROUP BY
  month,
  year,
  occupation_name;
