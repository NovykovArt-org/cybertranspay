# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

cursor/env-setup-578e
CyberTransPay is a pre-MVP cross-border payments platform with three components:

| Component | Directory | Stack | Status |
|-----------|-----------|-------|--------|
| Routing Engine (backend) | `backend/routing-engine/` | Rust (Axum + Tokio) | Functional — stateless HTTP API on port 8080 |
| Flutter client (frontend) | `frontend/` | Flutter/Dart | Functional — connects to backend |
| Smart contracts | `smart-contracts/` | Planned (EVM/Solana/Cosmos) | Placeholder only |
| Infrastructure | `terraform/` | Terraform → GCP | Has known validation issues |

The backend is fully **stateless/in-memory** — no database or external service is required to run it.

### Development tooling

- **Rust stable** (>= edition 2021; latest stable recommended — older pinned versions may fail to compile due to crate MSRV bumps). Installed via `rustup`.
- **Flutter SDK 3.24.x** (Dart >= 3.5.0). Installed at `/home/ubuntu/flutter-sdk`; add to PATH: `export PATH="/home/ubuntu/flutter-sdk/bin:$PATH"`.
- **Terraform >= 1.9.0** installed via HashiCorp APT repository.

### Running checks (matching CI/CD)

CI/CD (`.github/workflows/ci-cd.yml`) runs three conditional checks:

```sh
# Rust backend
cd backend && cargo test --all

# Flutter frontend
cd frontend && flutter pub get && flutter analyze && flutter test

# Terraform (known pre-existing failures — see below)
cd terraform && terraform fmt -check -recursive
terraform init -backend=false && terraform validate
```

### Starting the backend

```sh
cd backend && cargo run -p routing-engine
```

Listens on `http://localhost:8080`. Key endpoints: `/health`, `/v1/routes/quote`, `/v1/assets`, `/v1/rates/spot`, `/v1/transfers`. Auth is off by default (`AUTH_REQUIRED=false`). See `backend/README.md` for API examples.

### Known pre-existing issues

- **Merge conflict markers** in `terraform/variables.tf` — causes `terraform fmt` and `terraform init` to fail.
- **Formatting drift**: several `.tf` files do not pass `terraform fmt -check`.
- The CI/CD pipeline is conditional (`if [ -d "terraform" ]`) and these issues do not block the Rust or Flutter checks.
- **Flutter `prefer_const_constructors` info**: `flutter analyze` reports one info-level lint in `lib/main.dart` — not an error.
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
main
