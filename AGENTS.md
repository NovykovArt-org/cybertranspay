# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

CyberTransPay is a pre-MVP cross-border payments platform. The repository now includes:

- `backend/` — Rust workspace with the `routing-engine` Axum HTTP API.
- `frontend/` — Flutter client for mobile, web, and desktop targets.
- `terraform/` — Google Cloud infrastructure-as-code.
- `smart-contracts/` — placeholder/documentation area for future multi-chain work.
- `docs/` — project and deployment documentation.

### Development tooling

- **Rust stable >= 1.95** for backend development and tests.
- **Flutter 3.24.x** with Dart 3.5.x for frontend development and tests.
- **Terraform 1.9.x** for infrastructure validation.
- There is no `package.json`; JavaScript/Node tooling is not currently part of this repo.

### Running checks (matching CI/CD)

The CI/CD pipeline (`.github/workflows/ci-cd.yml`) runs Rust, Flutter, and Terraform checks:

```sh
cd backend && cargo test --all
cd frontend && flutter pub get && flutter analyze && flutter test
cd terraform && terraform fmt -check -recursive && terraform init -backend=false && terraform validate
```

- `cargo test --all` — runs all Rust workspace tests.
- `flutter pub get && flutter analyze && flutter test` — resolves frontend dependencies, runs analyzer, and executes Flutter tests.
- `terraform fmt -check -recursive` — checks Terraform formatting.
- `terraform init -backend=false && terraform validate` — validates Terraform without connecting to the GCS backend.

### Running services locally

Backend routing engine:

```sh
cd backend
cargo run -p routing-engine
```

The backend listens on `PORT` or defaults to `8080`; `/health` is public.

Frontend:

```sh
cd frontend
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=API_KEY=your-secret-key
```

`API_KEY` is only needed when backend auth is enabled with `AUTH_REQUIRED=true`.

### Known pre-existing issues

No known always-failing local checks are currently documented. If a check fails, treat it as actionable unless a newer note in this file says otherwise.
