# Backend

Rust workspace for CyberTransPay core services.

| Crate | Description |
|-------|-------------|
| `routing-engine` | HTTP API for payment route quotes and health checks |

## Routing engine

`POST /v1/routes/quote` accepts JSON:

```json
{
  "from_asset": "USDT",
  "to_asset": "EUR",
  "amount": 1000,
  "preference": "cheapest"
}
```

`preference`: `cheapest` | `fastest` | `compliant`

The engine scores routes from an internal catalog (bank, stablecoin, bridge, CEX, CBDC rails) and returns up to three ranked options.

## Run locally

```bash
cd backend
cargo run -p routing-engine
```

- Health: `http://localhost:8080/health`
- Quote: `curl -X POST http://localhost:8080/v1/routes/quote -H 'Content-Type: application/json' -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"fastest"}'`

Environment:

| Variable | Default |
|----------|---------|
| `PORT` | `8080` |
| `RUST_LOG` | (optional) `routing_engine=debug` |
