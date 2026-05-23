# Backend

Rust workspace for CyberTransPay core services.

| Crate | Description |
|-------|-------------|
| `routing-engine` | HTTP API for payment route quotes and health checks |

## Routing engine

### Live rates

Spot rates from public APIs (60s cache):

- **CoinGecko** — USDT, USDC, BTC → USD
- **Frankfurter** — fiat crosses (USD base)

### Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_REQUIRED` | `false` locally | Require `X-API-Key` on `/v1/*` |
| `AUTH_API_KEYS` | — | Comma-separated valid keys |
| `PORT` | `8080` | HTTP port |

`/health` is always public.

### API

`POST /v1/routes/quote`:

```json
{
  "from_asset": "USDT",
  "to_asset": "EUR",
  "amount": 1000,
  "preference": "cheapest"
}
```

Response includes `spot_rate`, `rate_source`, `live_pricing`, `priced_at`, and ranked `routes`.

## Run locally

```bash
cd backend
export AUTH_REQUIRED=false
cargo run -p routing-engine
```

With auth:

```bash
export AUTH_REQUIRED=true
export AUTH_API_KEYS=dev-secret-key
curl -H 'X-API-Key: dev-secret-key' -X POST http://localhost:8080/v1/routes/quote \
  -H 'Content-Type: application/json' \
  -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"fastest"}'
```
