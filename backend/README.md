# Backend

Rust workspace for CyberTransPay core services.

| Crate | Description |
|-------|-------------|
| `routing-engine` | HTTP API for payment route quotes and health checks |

## Run locally

```bash
cd backend
cargo run -p routing-engine
```

Health: `http://localhost:8080/health`
