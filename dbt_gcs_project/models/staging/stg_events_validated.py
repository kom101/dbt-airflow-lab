import pandas as pd
import json

def model(dbt, session):
    # Konfiguracja modelu
    dbt.config(
        materialized="table",
        submission_method="serverless",
        dataproc_region="europe-west1",
        intermediate_storage_bucket="ecommerce-data-python-raw",
        meta={
            "network": "dbt-python-vpc",
            "subnetwork": "dbt-python-subnet"
        }
    )

   
    spark = session
    
    table_name = "lrz-ecommerce-test.ecommerce_data_lr.raw_events_csv"
    
    df_spark = (spark.read.format("bigquery")
                .option("query", f"SELECT * FROM `{table_name}`")
                .option("materializationProject", "lrz-ecommerce-test")
                .option("materializationDataset", "ecommerce_data_lr")
                .load())
    
    # Konwersja do Pandas
    df = df_spark.toPandas()

    def validate_event(row):
        try:
            # Zakładamy, że kolumna 'event_body' zawiera string JSON
            payload = json.loads(row['event_body'])
            
            # Walidacja pól wymaganych dla zamówień
            required_fields = ['order_id', 'customer_id', 'items']
            if all(field in payload for field in required_fields):
                # Dodatkowa walidacja - items powinien być listą
                if isinstance(payload['items'], list):
                    return True
            return False
        except Exception as e:
            return False

    # Aplikujemy walidację
    df['is_valid'] = df.apply(validate_event, axis=1)

    # Filtrujemy tylko poprawne eventy
    df_clean = df[df['is_valid'] == True].drop(columns=['is_valid'])
    

    df_clean = df_clean.reset_index(drop=True)
    return df_clean
