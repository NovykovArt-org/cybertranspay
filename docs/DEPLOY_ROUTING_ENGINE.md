# Деплой routing-engine через Cloud Build

**Проект:** `cybertranspay` · **регион:** `europe-west1` · **сервис:** `routing-engine`

---

## Шаг 0 — один раз

```cmd
gcloud auth login
gcloud auth application-default login
gcloud config set project cybertranspay
```

---

## Шаг 1 — Terraform (инфраструктура)

```cmd
cd C:\Users\tyom2001\Desktop\cybertranspay-final\cybertranspay\terraform
terraform init
terraform apply
```

При запросе переменных:

| Переменная | Значение |
|------------|----------|
| `project_id` | `cybertranspay` |
| `auth_api_keys` | длинный ключ, сохраните его |
| `allow_public_routing_api` | `true` для MVP* |

\* Cloud Run по умолчанию блокирует HTTP без IAM. При `true` запросы доходят до приложения; `/v1/*` защищены заголовком `X-API-Key`.

Сохраните **API key** — нужен для curl и Flutter.

---

## Шаг 2 — Cloud Build (сборка + деплой)

Из **корня** репозитория (не из `backend`):

```cmd
cd C:\Users\tyom2001\Desktop\cybertranspay-final\cybertranspay
gcloud builds submit --config=cloudbuild.yaml --project=cybertranspay
```

Cloud Build выполнит:
1. `docker-build` — Rust → образ
2. `docker-push` → Artifact Registry
3. `deploy-cloud-run` → сервис `routing-engine`

Сборка Rust ~10–20 мин (машина `E2_HIGHCPU_8`).

---

## Шаг 3 — проверка

URL сервиса:

```cmd
gcloud run services describe routing-engine --region=europe-west1 --project=cybertranspay --format="value(status.url)"
```

Health (без ключа):

```cmd
curl https://ВАШ-URL/health
```

Quote (с ключом из terraform):

```cmd
curl -H "X-API-Key: ВАШ-КЛЮЧ" -X POST https://ВАШ-URL/v1/routes/quote -H "Content-Type: application/json" -d "{\"from_asset\":\"USDT\",\"to_asset\":\"EUR\",\"amount\":1000,\"preference\":\"cheapest\"}"
```

---

## Flutter

```cmd
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=https://ВАШ-URL --dart-define=API_KEY=ВАШ-КЛЮЧ
```

---

## Если сборка упала

Список сборок:

```cmd
gcloud builds list --region=europe-west1 --project=cybertranspay --limit=3
```

Лог (подставьте BUILD_ID):

```cmd
gcloud builds describe BUILD_ID --region=europe-west1 --project=cybertranspay
gcloud logging read "resource.type=build AND resource.labels.build_id=BUILD_ID" --project=cybertranspay --limit=30 --format="value(textPayload)"
```

Console: https://console.cloud.google.com/cloud-build/builds?project=cybertranspay

---

## Не используйте

- Deploy from source / zip в Console (`cybertranspay-backend`) — для Rust не подходит
- `gcloud builds submit` из папки `backend` — нужен корень репо (там `cloudbuild.yaml`)
