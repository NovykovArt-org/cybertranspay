# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

CyberTransPay is a pre-MVP cross-border payments platform. The repository currently contains:

- `backend/` — Rust workspace with the Axum `routing-engine` service.
- `frontend/` — Flutter client with quote UI and API client tests.
- `terraform/` — Google Cloud infrastructure.
- `scripts/` — Cloud Build, Cloud Run, and IAM helper scripts.
- `docs/` — deployment and product documentation.

### Development tooling

- **Rust stable** is required for backend checks.
- **Flutter 3.24.x** is used by CI for frontend checks.
- **Terraform >= 1.9.0** is required for infrastructure checks.
- **gcloud CLI** is required for Cloud Build / Cloud Run deployment scripts.

### Running checks (matching CI/CD)

The CI/CD pipeline (`.github/workflows/ci-cd.yml`) runs these checks when the matching directories exist:

```sh
cd backend && cargo test --all
cd frontend && flutter pub get && flutter analyze && flutter test
cd terraform && terraform fmt -check && terraform validate
```

- Backend: `cargo test --all`.
- Frontend: `flutter pub get`, `flutter analyze`, and `flutter test`.
- Terraform: `terraform fmt -check -recursive`, `terraform init -backend=false`, and `terraform validate`.

### Known pre-existing issues

- Windows port `8080` is often occupied. Use Cloud Run proxy port `8081` for manual cloud checks.
- Cloud Build manual deploy works through `scripts/update-routing-engine.cmd` / `.sh`.
- Cloud Build trigger setup is available through `scripts/setup-cloudbuild-trigger.cmd` / `.sh`; GitHub connection in Cloud Build may still need one-time setup.
- `terraform fmt -check -recursive` currently reports formatting drift in tracked `terraform/terraform.tfvars`; avoid normalizing it unless you intentionally want to touch environment-specific values.

### Local and cloud checks

- Local backend: `cd backend && cargo run -p routing-engine` (defaults to port `8080`, auth disabled unless env vars are set).
- Cloud proxy: `gcloud run services proxy routing-engine --region=europe-west1 --project=cybertranspay --port=8081`.
- Cloud API calls to `/v1/*` require `X-API-Key`; never commit real API keys.
