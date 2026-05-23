# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

CyberTransPay is a pre-MVP cross-border payments platform. The repository currently contains **only Terraform infrastructure-as-code** and documentation — no application source code (`backend/`, `frontend/`, `smart-contracts/`) exists yet.

### Development tooling

- **Terraform >= 1.9.0** is the only required development tool. It is installed system-wide via the HashiCorp APT repository.
- There are no `package.json`, `Cargo.toml`, `pubspec.yaml`, or other application dependency files.

### Running checks (matching CI/CD)

The CI/CD pipeline (`.github/workflows/ci-cd.yml`) runs three conditional checks. Only the Terraform check is currently relevant:

```sh
cd terraform && terraform fmt -check && terraform validate
```

- `terraform fmt -check -recursive` — linting/formatting check.
- `terraform init -backend=false` then `terraform validate` — structural validation without connecting to the GCS backend.

### Known pre-existing issues

- **Duplicate backend block**: Both `terraform/backend.tf` and `terraform/providers.tf` define a `backend "gcs"` block. `terraform init` fails with "Duplicate 'backend' configuration block".
- **Missing module variables**: Terraform modules under `terraform/modules/` do not declare `variable` blocks for `project_id`, `region`, or `github_app_installation_id`, but `terraform/main.tf` passes these arguments, causing "Unsupported argument" errors during init/validate.
- **Formatting drift**: Several `.tf` files do not pass `terraform fmt -check`.
- The CI/CD pipeline gracefully handles these with `|| echo "Terraform skipped"`.

### No backend/frontend to run

Until `backend/` (Rust/Axum) or `frontend/` (Flutter) directories are created, there are no services to start or test beyond Terraform validation.
