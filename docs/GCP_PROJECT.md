# GCP Project: cybertranspay

| Field | Value |
|-------|-------|
| **Project ID** | `cybertranspay` |
| **Project number** | `1079379369218` |
| **Region** | `europe-west1` |
| **Artifact Registry** | `europe-west1-docker.pkg.dev/cybertranspay/cybertranspay` |
| **Cloud Run service** | `routing-engine` |
| **Terraform state bucket** | `gs://cybertranspay-terraform-state` |

## Быстрый деплой

На машине с `gcloud` auth:

```bash
export PROJECT_ID="cybertranspay"
export PROJECT_NUMBER="1079379369218"
export AUTH_API_KEYS="$(openssl rand -hex 32)"
./scripts/gcp-apply.sh
```

Сохраните `AUTH_API_KEYS` — он понадобится для Flutter и curl.

## Flutter (после деплoy)

```bash
URL=$(terraform -chdir=terraform output -raw routing_engine_url)

flutter run -d chrome \
  --dart-define=API_BASE_URL="$URL" \
  --dart-define=API_KEY="ваш-ключ"
```

## Проверка API

```bash
curl "https://routing-engine-XXXXX-ew.a.run.app/health"

curl -H "X-API-Key: ваш-ключ" \
  -X POST "https://routing-engine-XXXXX-ew.a.run.app/v1/routes/quote" \
  -H 'Content-Type: application/json' \
  -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}'
```

## GCP Console

- [Project dashboard](https://console.cloud.google.com/home/dashboard?project=cybertranspay)
- [Cloud Run](https://console.cloud.google.com/run?project=cybertranspay)
- [Artifact Registry](https://console.cloud.google.com/artifacts?project=cybertranspay)
- [Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cybertranspay)
- [Cloud Build troubleshooting](../docs/CLOUD_BUILD.md)

## Аутентификация gcloud (один раз)

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project cybertranspay
```

Или service account:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa-key.json
export PROJECT_ID=cybertranspay
./scripts/gcp-apply.sh
```
