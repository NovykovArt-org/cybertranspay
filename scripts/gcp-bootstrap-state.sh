#!/usr/bin/env bash
# Create GCS bucket for Terraform remote state (run once before terraform init).
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-cybertranspay}"
REGION="${REGION:-europe-west1}"
BUCKET="${TF_STATE_BUCKET:-cybertranspay-terraform-state}"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "gcloud not found. Install: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

gcloud config set project "$PROJECT_ID"

if gcloud storage buckets describe "gs://${BUCKET}" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Bucket gs://${BUCKET} already exists"
else
  echo "Creating gs://${BUCKET}..."
  gcloud storage buckets create "gs://${BUCKET}" \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --uniform-bucket-level-access
fi

echo "State bucket ready: gs://${BUCKET}"
