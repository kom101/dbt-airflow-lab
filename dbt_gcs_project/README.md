# dbt GCS Pipeline: Ingest ➔ Validate ➔ Standardize 🚀

Ten projekt dbt stanowi rdzeń analityczny laboratorium, realizując proces transformacji danych w architekturze **Medallion** (Bronze ➔ Silver) przy użyciu Google BigQuery.

## 🛠️ Opis Architektury

Projekt implementuje proces "Ingest ➔ Validate ➔ Standardize" z wykorzystaniem:
- **Python Models** dla zaawansowanej walidacji danych (Dataproc Serverless).
- **SQL Models** dla transformacji i standaryzacji w BigQuery.
- **External Tables** do bezpośredniego odczytu z Google Cloud Storage.

Projekt zawiera przykładowe dane testowe z poprawnymi i niepoprawnymi rekordami, które pozwalają przetestować walidację danych na różnych poziomach.

## 📂 Struktura Projektu i Modeli

```text
models/
├── staging/
│   ├── [schema.yml](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/staging/schema.yml)          # Definicja źródeł danych i tabel zewnętrznych
│   └── [stg_events_validated.py](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/staging/stg_events_validated.py)  # Walidacja danych w Pythonie
└── core/
    ├── [fct_orders.sql](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/core/fct_orders.sql)      # Standaryzacja zamówień
    └── [fct_order_items.sql](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/core/fct_order_items.sql) # Standaryzacja pozycji zamówień
```

## 🧪 Dane Testowe

Projekt zawiera plik `orders_data.csv` z przykładowymi danymi zawierającymi zarówno poprawne jak i niepoprawne rekordy:

- **Rekordy 1, 2, 4, 5, 6, 7, 9, 10**: Poprawne rekordy z zamówieniami.
- **Rekord 3**: Uszkodzony format JSON (`--BŁĄD DANYCH--`) - odrzucany przez walidację.
- **Rekord 8**: Poprawny JSON, ale brak wymaganych pól (`order_id`, `items`) - odrzucany przez walidację.

Model Pythonowy ([stg_events_validated.py](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/staging/stg_events_validated.py)) zawiera zaawansowaną walidację:
- Sprawdza poprawność składni JSON.
- Weryfikuje obecność wymaganych pól.
- Sprawdza typ danych dla tablicy `items`.

## 🔧 Konfiguracja i Uruchomienie

### **Wymagane kroki konfiguracyjne:**

1.  **Zainstaluj `gcloud` CLI** i zaloguj się: `gcloud auth login`.
2.  **Projekt GCP**: Projekt jest skonfigurowany z ID: `lrz-ecommerce-test`.
3.  **Uruchom skrypt konfiguracyjny**: `./setup_gcp.sh` lub `.\setup_gcp.ps1`. Skrypt automatycznie prześle plik `orders_data.csv` do bucketu.
4.  **Uwierzytelnienie**: `gcloud auth application-default login`.

### **Komendy dbt wewnątrz kontenera:**
```bash
# Instalacja pakietów (dbt_utils, dbt_external_tables)
# UWAGA: Paczki są instalowane w /tmp/dbt_packages dla izolacji
dbt deps

# Tworzenie tabel zewnętrznych
dbt run-operation stage_external_sources

# Uruchomienie potoku (target i dbt_packages są w /tmp)
dbt run

# Testowanie jakości danych
dbt test
```

## 🏗️ Etapy Przetwarzania

### **Etap 1: Konfiguracja źródła (Bronze)**
Plik [schema.yml](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/staging/schema.yml) definiuje źródło danych z Google Cloud Storage. Wykorzystujemy `dbt_external_tables` do mapowania plików CSV na tabele BigQuery bez konieczności ich fizycznego ładowania.

### **Etap 2: Walidacja w Pythonie (Silver Validation)**
Model [stg_events_validated.py](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/staging/stg_events_validated.py) wczytuje dane i przeprowadza walidację JSON-ów. Wykorzystuje **Dataproc Serverless** do izolowanego przetwarzania Pythonowego, co pozwala na znacznie bardziej elastyczną obsługę błędów niż czysty SQL.

### **Etap 3: Standaryzacja w SQL (Silver/Gold)**
Dwa modele SQL przekształcają zwalidowane dane w relacyjną strukturę:
1.  [fct_orders.sql](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/core/fct_orders.sql) - ekstrahuje dane o zamówieniach.
2.  [fct_order_items.sql](file:///d:/projekty/dbt-airflow-lab/dbt_gcs_project/models/core/fct_order_items.sql) - ekstrahuje dane o pozycjach zamówień.

## 📊 Zalety tej architektury

1.  **Python dla walidacji**: Lepsza obsługa błędów formatowania JSON niż w SQL.
2.  **SQL dla modelowania**: Zoptymalizowane przetwarzanie dużych zbiorów danych w BigQuery.
3.  **Lineage**: Jasna ścieżka danych: GCS ➔ Python Model (Clean) ➔ SQL Models (Standardized).
4.  **Scalability**: Wykorzystanie rozwiązań serverless (BigQuery, Dataproc) eliminuje potrzebę zarządzania infrastrukturą.

---
*Dokumentacja techniczna projektu dbt.*
