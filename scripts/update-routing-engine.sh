#!/usr/bin/env bash
# One-command update: git pull + Cloud Build (build, push, update Cloud Run)
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-cybertranspay}"
REGION="${REGION:-europe-west1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"
echo "=== CyberTransPay routing-engine update ==="

echo "[1/2] git pull..."
git pull origin main

echo "[2/2] Cloud Build..."
gcloud builds submit --config=cloudbuild.yaml --project="$PROJECT_ID"

URL="$(gcloud run services describe routing-engine \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --format='value(status.url)')"

echo
echo "=== SUCCESS ==="
echo "Cloud Run URL: $URL"
echo
echo "Test locally (keep proxy running):"
echo "  gcloud run services proxy routing-engine --region=$REGION --project=$PROJECT_ID --port=8080"
echo "  curl http://127.0.0.1:8080/health"
