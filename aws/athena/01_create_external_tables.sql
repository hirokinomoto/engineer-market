-- Amazon Athena external table definitions
-- Replace <your-s3-bucket> with your actual S3 bucket name before executing.

CREATE DATABASE IF NOT EXISTS engineer_market;

DROP TABLE IF EXISTS engineer_market.estat_job_market_2012_2022;

CREATE EXTERNAL TABLE engineer_market.estat_job_market_2012_2022 (
  month string,
  occupation_name string,
  metric_name string,
  value double,
  unit string,
  source_file string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  "separatorChar" = ",",
  "quoteChar" = "\""
)
LOCATION 's3://<your-s3-bucket>/processed/estat_job_market_2012_2022/'
TBLPROPERTIES (
  "skip.header.line.count" = "1"
);

DROP TABLE IF EXISTS engineer_market.estat_job_market_2023_2025;

CREATE EXTERNAL TABLE engineer_market.estat_job_market_2023_2025 (
  month string,
  occupation_name string,
  metric_name string,
  value double,
  unit string,
  source_file string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
  "separatorChar" = ",",
  "quoteChar" = "\""
)
LOCATION 's3://<your-s3-bucket>/processed/estat_job_market_2023_2025/'
TBLPROPERTIES (
  "skip.header.line.count" = "1"
);
