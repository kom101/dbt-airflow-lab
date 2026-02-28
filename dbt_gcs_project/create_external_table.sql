CREATE OR REPLACE EXTERNAL TABLE `lrz-ecommerce-test.ecommerce_data_lr.raw_events_csv`
(
  event_id STRING,
  event_timestamp TIMESTAMP,
  event_type STRING,
  event_body STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://ecommerce-data-python-raw/events/*.csv'],
  skip_leading_rows = 1
);
