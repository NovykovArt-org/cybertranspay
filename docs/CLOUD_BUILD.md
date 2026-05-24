# Cloud Build — troubleshooting

Build: [`6aabd325-e325-4f63-b91d-87ce8da86604`](https://console.cloud.google.com/cloud-build/builds;region=europe-west1/6aabd325-e325-4f63-b91d-87ce8da86604?project=1079379369218)  
Project: **cybertranspay** (`1079379369218`) · Region: **europe-west1**

## Частые причины падения

| Шаг | Ошибка | Решение |
|-----|--------|---------|
| `docker-push` | `denied` / `not found` | `terraform apply` — создаёт Artifact Registry; IAM для Cloud Build SA |
| `docker-build` | Rust OOM / timeout | В `cloudbuild.yaml`: `machineType: E2_HIGHCPU_8`, `timeout: 1800s` |
| `deploy-cloud-run` | `NOT_FOUND: Service routing-engine` | Сначала `terraform apply`, либо deploy создаст минимальный сервис |
| Image tag | Пустой тег `:`` | Используйте `$BUILD_ID`, не `$SHORT_SHA` (пуст при ручном submit) |

## IAM для Cloud Build

Service account: `1079379369218@cloudbuild.gserviceaccount.com`

Terraform выдаёт роли:
- `roles/artifactregistry.writer`
- `roles/run.admin`
- `roles/iam.serviceAccountUser`

После изменения IAM:

```bash
cd terraform && terraform apply
```

## Перезапуск сборки

```bash
gcloud builds submit --config=cloudbuild.yaml --project=cybertranspay
```

## Проверка логов

```bash
gcloud builds log 6aabd325-e325-4f63-b91d-87ce8da86604 \
  --region=europe-west1 \
  --project=cybertranspay
```

## После успешной сборки

```bash
URL=$(gcloud run services describe routing-engine \
  --region=europe-west1 --project=cybertranspay \
  --format='value(status.url)')

curl "$URL/health"
```

Если auth включён — добавьте `-H "X-API-Key: ваш-ключ"`.
