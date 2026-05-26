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

## API key auth (optional)

By default auth is **off**. Enable locally:

```cmd
set AUTH_REQUIRED=true
set AUTH_API_KEYS=your-secret-key
cargo run -p routing-engine
```

Cloud Run:

```cmd
scripts\set-routing-engine-auth.cmd
```

Quote with auth:

```bash
curl -X POST http://localhost:8080/v1/routes/quote \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-key" \
  -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}'
```

`/health` is always public; `/v1/*` requires `X-API-Key` when `AUTH_REQUIRED=true`.

## Quote and transfer persistence

By default, quotes and mock transfers are kept in memory. To persist them as
JSON files across process restarts, set either a shared data directory:

```bash
CTP_DATA_DIR=.data cargo run -p routing-engine
```

or explicit file paths:

```bash
QUOTE_STORE_PATH=.data/quotes.json \
TRANSFER_STORE_PATH=.data/transfers.json \
cargo run -p routing-engine
```

For Cloud Run, use a mounted writable volume for these paths; the container
filesystem alone is ephemeral.

## Assets and spot rate

```bash
curl http://localhost:8080/v1/assets -H "X-API-Key: your-secret-key"

curl "http://localhost:8080/v1/rates/spot?from=USDT&to=EUR" -H "X-API-Key: your-secret-key"
```

Supported assets: USD, EUR, GBP, CHF, CNY, JPY, PLN, TRY, RUB, AED, USDT, USDC, BTC, ETH.

## Live quote API

```bash
curl -X POST http://localhost:8080/v1/routes/quote \
  -H "Content-Type: application/json" \
  -d '{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}'
```

Response includes `quote_id` and `expires_at` (default TTL 300s, override with `QUOTE_TTL_SECS`).

Fetch a stored quote:

```bash
curl http://localhost:8080/v1/quotes/{quote_id} -H "X-API-Key: your-secret-key"
```

## Mock transfers

Execute a quoted route (mock — status is immediately `completed`):

```bash
curl -X POST http://localhost:8080/v1/transfers \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-key" \
  -d '{"quote_id":"<quote_id>","route_id":"stablecoin-tron"}'

curl http://localhost:8080/v1/transfers/{transfer_id} -H "X-API-Key: your-secret-key"
```

- **Rates:** CoinGecko (USDT, USDC, BTC, ETH) + Frankfurter (fiat), cached 60s
- **Routes:** ranked by `cheapest` | `fastest` | `compliant` (top 3)
