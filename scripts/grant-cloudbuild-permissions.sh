#!/usr/bin/env bash
# Grant Cloud Build permissions for project cybertranspay (1079379369218)
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-cybertranspay}"
REGION="${REGION:-europe-west1}"
PROJECT_NUMBER="${PROJECT_NUMBER:-1079379369218}"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
CLOUD_RUN_ROBOT="service-${PROJECT_NUMBER}@serverless-robot-prod.iam.gserviceaccount.com"

echo "Creating Artifact Registry (ignore error if exists)..."
gcloud artifacts repositories create cybertranspay \
  --repository-format=docker \
  --location="$REGION" \
  --project="$PROJECT_ID" 2>/dev/null || true

echo "Granting IAM to Compute default SA..."
for role in artifactregistry.writer run.admin logging.logWriter; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$COMPUTE_SA" \
    --role="roles/$role" \
    --quiet
done

echo "Granting IAM to Cloud Build SA..."
for role in artifactregistry.writer run.admin iam.serviceAccountUser logging.logWriter; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$CLOUDBUILD_SA" \
    --role="roles/$role" \
    --quiet
done

echo "Granting Artifact Registry reader to Cloud Run service agent..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$CLOUD_RUN_ROBOT" \
  --role="roles/artifactregistry.reader" \
  --quiet

echo "Granting Compute SA permission to act as itself..."
gcloud iam service-accounts add-iam-policy-binding "$COMPUTE_SA" \
  --member="serviceAccount:$COMPUTE_SA" \
  --role="roles/iam.serviceAccountUser" \
  --project="$PROJECT_ID" \
  --quiet

echo "Done. Update with: scripts/update-routing-engine.sh"
