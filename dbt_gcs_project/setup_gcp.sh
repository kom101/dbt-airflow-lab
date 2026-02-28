#!/bin/bash

# Skrypt do kompleksowej konfiguracji projektu GCP pod dbt Python Models (Dataproc Serverless)

# 1. ZMIENNE
PROJECT_ID="lrz-ecommerce-test"
REGION="europe-west1"
BUCKET_NAME="ecommerce-data-python-raw"
DATASET_NAME="ecommerce_data_lr"
VPC_NAME="dbt-python-vpc"
SUBNET_NAME="dbt-python-subnet"
SUBNET_RANGE="10.0.0.0/24"

echo "Rozpoczynam konfigurację projektu GCP: $PROJECT_ID..."

# 2. LOGOWANIE
echo "Krok 1: Sprawdzanie uwierzytelnienia..."
gcloud auth login
gcloud auth application-default login

# 3. WYBÓR PROJEKTU
echo "Krok 2: Ustawianie projektu $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# 4. WŁĄCZANIE API
echo "Krok 3: Włączanie API..."
gcloud services enable bigquery.googleapis.com \
                       dataproc.googleapis.com \
                       storage.googleapis.com \
                       compute.googleapis.com

# 5. KONFIGURACJA SIECI (Kluczowe dla Python Models!)
echo "Krok 4: Konfiguracja VPC ($VPC_NAME)..."
gcloud compute networks create $VPC_NAME --subnet-mode=custom 2>/dev/null
gcloud compute networks subnets create $SUBNET_NAME \
    --network=$VPC_NAME \
    --range=$SUBNET_RANGE \
    --region=$REGION \
    --enable-private-ip-google-access 2>/dev/null

# 6. ZASOBY DANYCH
echo "Krok 5: Tworzenie Bucket i Dataset..."
gsutil mb -l $REGION gs://$BUCKET_NAME 2>/dev/null
bq mk --dataset --location=$REGION $PROJECT_ID:$DATASET_NAME 2>/dev/null

# Przesłanie danych testowych
if [ -f "orders_data.csv" ]; then
    gsutil cp orders_data.csv gs://$BUCKET_NAME/events/
fi

echo -e "\nKONFIGURACJA ZAKOŃCZONA!"
echo "1. Sprawdź profiles.yml (Project: $PROJECT_ID)"
echo "2. Uruchom: dbt deps && dbt run"
