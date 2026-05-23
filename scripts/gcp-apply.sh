#!/usr/bin/env bash
# Full GCP bootstrap: APIs + Terraform + optional Cloud Build deploy.
#
# Usage:
#   export PROJECT_ID="your-gcp-project"
#   export REGION="europe-west1"
#   export AUTH_API_KEYS="key1,key2"
#   ./scripts/gcp-apply.sh
#
# Requires: gcloud, terraform, docker (for local image push)

set -euo pipefail

PROJECT_ID="${PROJECT_ID:?Set PROJECT_ID}"
REGION="${REGION:-europe-west1}"
AUTH_API_KEYS="${AUTH_API_KEYS:?Set AUTH_API_KEYS (comma-separated)}"
TF_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Installing Google Cloud SDK..."
  curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
  export PATH="$HOME/google-cloud-sdk/bin:$PATH"
fi

gcloud config set project "$PROJECT_ID"
gcloud auth application-default login --quiet || true

echo "==> Terraform apply"
cd "$TF_DIR"
terraform init
terraform apply -auto-approve \
  -var="project_id=${PROJECT_ID}" \
  -var="region=${REGION}" \
  -var="auth_api_keys=${AUTH_API_KEYS}" \
  -var="auth_required=true" \
  -var="allow_public_routing_api=false"

ROUTING_URL="$(terraform output -raw routing_engine_url)"
echo "Routing engine URL: ${ROUTING_URL}"

if command -v gcloud >/dev/null 2>&1; then
  echo "==> Cloud Build deploy (optional)"
  gcloud builds submit "$(dirname "$0")/.." \
    --config=cloudbuild.yaml \
    --project="$PROJECT_ID" || echo "Cloud Build skipped (configure trigger manually)"
fi

echo "Done. Test:"
echo "  curl ${ROUTING_URL}/health"
echo "  curl -H 'X-API-Key: <key>' -X POST ${ROUTING_URL}/v1/routes/quote \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"from_asset\":\"USDT\",\"to_asset\":\"EUR\",\"amount\":1000,\"preference\":\"cheapest\"}'"
