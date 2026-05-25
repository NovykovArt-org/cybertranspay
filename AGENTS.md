# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

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
