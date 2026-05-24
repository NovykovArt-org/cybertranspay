# Обновление routing-engine через Cloud Build

**Проект:** `cybertranspay` · **сервис:** `routing-engine`  
**URL:** https://routing-engine-1079379369218.europe-west1.run.app

---

## Быстрое обновление (Windows)

После изменений в `backend/`:

```cmd
cd C:\Users\tyom2001\Desktop\cybertranspay-deploy
scripts\update-routing-engine.cmd
```

Или вручную:

```cmd
git pull origin main
gcloud builds submit --config=cloudbuild.yaml --project=cybertranspay
```

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

---

## Только build + push (без auto-deploy)

Если шаг `update-cloud-run` падает — используйте build-only и деплой вручную:

```cmd
gcloud builds submit --config=cloudbuild.build-only.yaml --project=cybertranspay
```

```cmd
gcloud run deploy routing-engine --image=europe-west1-docker.pkg.dev/cybertranspay/cybertranspay/routing-engine:latest --region=europe-west1 --project=cybertranspay --port=8080 --memory=512Mi
```

---

## Автозапуск при push в GitHub (опционально)

### Console

1. https://console.cloud.google.com/cloud-build/triggers?project=cybertranspay  
2. **Create trigger**  
3. Repository: `NovykovArt-org/cybertranspay`, branch `^main$`  
4. Configuration: **Cloud Build configuration file** → `cloudbuild.yaml`  
5. Save  

При каждом push в `main` — автоматическая сборка и обновление Cloud Run.

### CLI (если GitHub уже подключён)

```cmd
gcloud builds triggers create github --name=routing-engine-main --repo-name=cybertranspay --repo-owner=NovykovArt-org --branch-pattern=^main$ --build-config=cloudbuild.yaml --region=europe-west1 --project=cybertranspay
```

---

## IAM (один раз)

```cmd
scripts\grant-cloudbuild-permissions.cmd
```

Дополнительно для deploy из Cloud Build:

```cmd
gcloud iam service-accounts add-iam-policy-binding 1079379369218-compute@developer.gserviceaccount.com --member=serviceAccount:1079379369218-compute@developer.gserviceaccount.com --role=roles/iam.serviceAccountUser --project=cybertranspay
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
