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

## Live quote API

```bash
curl -X POST http://localhost:8080/v1/routes/quote \
  -H "Content-Type: application/json" \
  -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}'
```

- **Rates:** CoinGecko (USDT, USDC, BTC) + Frankfurter (EUR, GBP, CHF, CNY), cached 60s
- **Routes:** ranked by `cheapest` | `fastest` | `compliant` (top 3)
