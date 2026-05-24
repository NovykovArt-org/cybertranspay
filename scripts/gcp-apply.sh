#!/usr/bin/env bash
# Deploy CyberTransPay to GCP project cybertranspay (1079379369218).
#
# Usage:
#   gcloud auth application-default login
#   export AUTH_API_KEYS="$(openssl rand -hex 32)"
#   ./scripts/gcp-apply.sh
#
# Optional overrides:
#   PROJECT_ID=cybertranspay REGION=europe-west1

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-cybertranspay}"
PROJECT_NUMBER="${PROJECT_NUMBER:-1079379369218}"
REGION="${REGION:-europe-west1}"
AUTH_API_KEYS="${AUTH_API_KEYS:-$(openssl rand -hex 32)}"
TF_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Project: ${PROJECT_ID} (${PROJECT_NUMBER})"
echo "Region:  ${REGION}"
echo "API key: ${AUTH_API_KEYS:0:8}... (save this key)"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Installing Google Cloud SDK..."
  curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"
  export PATH="$HOME/google-cloud-sdk/bin:$PATH"
fi

gcloud config set project "$PROJECT_ID"

if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo "ERROR: No Application Default Credentials."
  echo "Run: gcloud auth application-default login"
  echo "Or:  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json"
  exit 1
fi

echo "==> Bootstrap Terraform state bucket"
bash "$(dirname "$0")/gcp-bootstrap-state.sh"

echo "==> Terraform apply"
cd "$TF_DIR"
terraform init -reconfigure
terraform apply -auto-approve \
  -var="project_id=${PROJECT_ID}" \
  -var="region=${REGION}" \
  -var="auth_api_keys=${AUTH_API_KEYS}" \
  -var="auth_required=true" \
  -var="allow_public_routing_api=false" \
  -var="github_app_installation_id=0"

ROUTING_URL="$(terraform output -raw routing_engine_url)"
echo ""
echo "Routing engine URL: ${ROUTING_URL}"
echo "API key (save):     ${AUTH_API_KEYS}"

echo "==> Cloud Build (build + deploy image)"
if gcloud builds submit "$ROOT" \
  --config="$ROOT/cloudbuild.yaml" \
  --project="$PROJECT_ID" \
  --substitutions="_REGION=${REGION}"; then
  echo "Cloud Build deploy complete"
else
  echo "WARN: Cloud Build failed — push image manually (see docs/DEPLOY_GCP.md)"
fi

cat <<EOF

=== Done ===

Health:
  curl "${ROUTING_URL}/health"

Quote:
  curl -H "X-API-Key: ${AUTH_API_KEYS}" \\
    -X POST "${ROUTING_URL}/v1/routes/quote" \\
    -H 'Content-Type: application/json' \\
    -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}'

Flutter:
  flutter run -d chrome \\
    --dart-define=API_BASE_URL=${ROUTING_URL} \\
    --dart-define=API_KEY=${AUTH_API_KEYS}

EOF
