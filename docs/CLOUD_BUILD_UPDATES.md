# Обновление routing-engine через Cloud Build

**Проект:** `cybertranspay` · **сервис:** `routing-engine`  
**URL:** https://routing-engine-1079379369218.europe-west1.run.app

---

## Первоначальная настройка (один раз)

### 1. IAM для Cloud Build

```cmd
scripts\grant-cloudbuild-permissions.cmd
```

Linux/macOS:

```bash
./scripts/grant-cloudbuild-permissions.sh
```

### 2. Автозапуск при push в GitHub (рекомендуется)

1. Подключите репозиторий:  
   https://console.cloud.google.com/cloud-build/triggers/connect?project=cybertranspay  
   → GitHub → `NovykovArt-org/cybertranspay`

2. Создайте trigger:

```cmd
scripts\setup-cloudbuild-trigger.cmd
```

Или вручную:

```cmd
gcloud builds triggers create github --name=routing-engine-main --repo-name=cybertranspay --repo-owner=NovykovArt-org --branch-pattern=^main$ --build-config=cloudbuild.yaml --region=europe-west1 --project=cybertranspay
```

После этого каждый **push в `main`** автоматически: собирает образ → push в Artifact Registry → обновляет Cloud Run.

### 3. Terraform (опционально)

IAM и trigger можно включить в Terraform:

```bash
cd terraform
terraform apply -var="project_id=cybertranspay" -var="create_cloud_build_trigger=true"
```

> Trigger в Terraform работает только после подключения GitHub в Console (`create_cloud_build_trigger = false` по умолчанию).

---

## Быстрое обновление вручную (Windows)

После изменений в `backend/`:

```cmd
cd C:\Users\tyom2001\Desktop\cybertranspay-deploy
scripts\update-routing-engine.cmd
```

Или:

```cmd
git pull origin main
gcloud builds submit --config=cloudbuild.yaml --project=cybertranspay
```

Linux/macOS: `./scripts/update-routing-engine.sh`

---

## Что делает `cloudbuild.yaml`

| Шаг | Действие |
|-----|----------|
| `docker-build` | Rust → Docker-образ |
| `docker-push` | Push в `europe-west1-docker.pkg.dev/cybertranspay/cybertranspay/routing-engine` |
| `update-cloud-run` | `gcloud run services update routing-engine --image=...:latest` |

> **Не использует** `--allow-unauthenticated` (org policy блокирует `allUsers`).

---

## Проверка после обновления

**Proxy** (окно 1 — не закрывать):

```cmd
gcloud run services proxy routing-engine --region=europe-west1 --project=cybertranspay --port=8080
```

**Проверка** (окно 2):

```cmd
curl http://127.0.0.1:8080/health
```

**Статус последней сборки:**

```cmd
gcloud builds list --region=europe-west1 --project=cybertranspay --limit=5
```

---

## Только build + push (без auto-deploy)

Если шаг `update-cloud-run` падает:

```cmd
gcloud builds submit --config=cloudbuild.build-only.yaml --project=cybertranspay
gcloud run deploy routing-engine --image=europe-west1-docker.pkg.dev/cybertranspay/cybertranspay/routing-engine:latest --region=europe-west1 --project=cybertranspay --port=8080 --memory=512Mi
```

---

## Доступ к API

| Способ | Команда |
|--------|---------|
| Локально (dev) | `gcloud run services proxy` → `http://127.0.0.1:8080` |
| С токеном | `gcloud auth print-identity-token` + `Authorization: Bearer` |
| Публичный URL | Заблокирован org policy (`allUsers`) |

Flutter dev:

```cmd
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8080
```
