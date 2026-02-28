# Skrypt do kompleksowej konfiguracji projektu GCP pod dbt Python Models (Dataproc Serverless)

# 1. ZMIENNE
$PROJECT_ID = "lrz-ecommerce-test"
$REGION = "europe-west1"                # Region wspierający Dataproc Serverless
$BUCKET_NAME = "ecommerce-data-python-raw"
$DATASET_NAME = "ecommerce_data_lr"
$VPC_NAME = "dbt-python-vpc"
$SUBNET_NAME = "dbt-python-subnet"
$SUBNET_RANGE = "10.0.0.0/24"

Write-Host "Rozpoczynam konfigurację projektu GCP: $PROJECT_ID..." -ForegroundColor Green

# 2. LOGOWANIE
Write-Host "Krok 1: Sprawdzanie uwierzytelnienia..." -ForegroundColor Yellow
gcloud auth login
gcloud auth application-default login

# 3. WYBÓR PROJEKTU
Write-Host "Krok 2: Ustawianie projektu $PROJECT_ID..." -ForegroundColor Yellow
$projectExists = gcloud projects list --filter="projectId=$PROJECT_ID" --format="value(projectId)"

if ($projectExists -eq $PROJECT_ID) {
    gcloud config set project $PROJECT_ID
} else {
    Write-Host "Próba utworzenia nowego projektu $PROJECT_ID..." -ForegroundColor Yellow
    gcloud projects create $PROJECT_ID --quiet
    gcloud config set project $PROJECT_ID
}

# 4. KONTROLA BILLINGU
Write-Host "`nKrok 3: Kontrola bilingu..." -ForegroundColor Yellow
$billingEnabled = gcloud billing projects describe $PROJECT_ID --format="value(billingEnabled)"
if ($billingEnabled -ne "True") {
    Write-Host "!!! UWAGA: Billing nie jest aktywny dla projektu $PROJECT_ID !!!" -ForegroundColor Red
    Write-Host "Otwórz: https://console.cloud.google.com/billing/projects i włącz biling." -ForegroundColor Yellow
    Read-Host "Gdy to zrobisz, naciśnij ENTER..."
}

# 5. WŁĄCZANIE API
Write-Host "`nKrok 4: Włączanie API..." -ForegroundColor Yellow
gcloud services enable bigquery.googleapis.com `
                       dataproc.googleapis.com `
                       storage.googleapis.com `
                       compute.googleapis.com

# 6. KONFIGURACJA SIECI (Kluczowe dla Python Models!)
Write-Host "Krok 5: Konfiguracja VPC ($VPC_NAME)..." -ForegroundColor Yellow
gcloud compute networks create $VPC_NAME --subnet-mode=custom 2>$null
gcloud compute networks subnets create $SUBNET_NAME `
    --network=$VPC_NAME `
    --range=$SUBNET_RANGE `
    --region=$REGION `
    --enable-private-ip-google-access 2>$null

# 7. ZASOBY DANYCH
Write-Host "Krok 6: Tworzenie Bucket i Dataset..." -ForegroundColor Yellow
gsutil mb -l $REGION gs://$BUCKET_NAME 2>$null
bq mk --dataset --location=$REGION ${PROJECT_ID}:${DATASET_NAME} 2>$null

# Przesłanie danych testowych
if (Test-Path "orders_data.csv") {
    gsutil cp orders_data.csv gs://$BUCKET_NAME/events/
}

Write-Host "`nKONFIGURACJA ZAKOŃCZONA!" -ForegroundColor Green
Write-Host "1. Sprawdź profiles.yml (Project: $PROJECT_ID)" -ForegroundColor Cyan
Write-Host "2. Uruchom: dbt deps && dbt run" -ForegroundColor Cyan
