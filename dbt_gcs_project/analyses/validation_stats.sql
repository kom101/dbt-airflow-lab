-- Sprawdzenie statystyk walidacji
WITH raw_data AS (
    -- Wszystkie rekordy z pliku CSV (tabela zewnętrzna)
    SELECT
        event_id,
        event_type,
        event_body
    FROM {{ source('gcs_raw', 'raw_events_csv') }}
),

validated_data AS (
    -- Tylko rekordy, które przeszły model Pythonowy
    SELECT
        event_id,
        event_type,
        event_body
    FROM {{ ref('stg_events_validated') }}
),

rejected_records AS (
    -- Rekordy obecne w CSV, ale nieobecne w tabeli po walidacji
    SELECT * FROM raw_data
    EXCEPT DISTINCT
    SELECT * FROM validated_data
)

SELECT
    (SELECT COUNT(*) FROM raw_data) as total_input_rows,
    (SELECT COUNT(*) FROM validated_data) as valid_rows_loaded,
    (SELECT COUNT(*) FROM rejected_records) as rejected_rows_count;
