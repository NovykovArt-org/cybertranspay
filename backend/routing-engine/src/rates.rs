use chrono::{DateTime, Utc};
use serde::Deserialize;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use thiserror::Error;
use tokio::sync::RwLock;

const CACHE_TTL: Duration = Duration::from_secs(60);

#[derive(Debug, Clone)]
pub struct SpotRate {
    pub rate: f64,
    pub source: String,
    pub fetched_at: DateTime<Utc>,
}

#[derive(Error, Debug)]
pub enum RateError {
    #[error("unsupported asset pair: {from} -> {to}")]
    UnsupportedPair { from: String, to: String },
    #[error("upstream rate provider failed: {0}")]
    Upstream(String),
}

#[derive(Clone)]
pub struct LiveRates {
    client: reqwest::Client,
    cache: Arc<RwLock<Option<CachedRates>>>,
    mock_rate: Option<f64>,
}

struct CachedRates {
    expires_at: std::time::Instant,
    fiat: HashMap<String, HashMap<String, f64>>,
    crypto_usd: HashMap<String, f64>,
}

#[derive(Deserialize)]
struct FrankfurterResponse {
    rates: HashMap<String, f64>,
}

#[derive(Deserialize)]
struct CoinGeckoResponse {
    #[serde(flatten)]
    coins: HashMap<String, HashMap<String, f64>>,
}

impl LiveRates {
    pub fn new() -> Self {
        Self {
            client: reqwest::Client::builder()
                .timeout(Duration::from_secs(10))
                .build()
                .expect("http client"),
            cache: Arc::new(RwLock::new(None)),
            mock_rate: None,
        }
    }

    pub fn mock(rate: f64) -> Self {
        Self {
            client: reqwest::Client::new(),
            cache: Arc::new(RwLock::new(None)),
            mock_rate: Some(rate),
        }
    }

    pub fn is_live(&self) -> bool {
        self.mock_rate.is_none()
    }

    pub async fn spot_rate(&self, from: &str, to: &str) -> Result<SpotRate, RateError> {
        let from = from.trim().to_uppercase();
        let to = to.trim().to_uppercase();

        if from == to {
            return Ok(SpotRate {
                rate: 1.0,
                source: "identity".into(),
                fetched_at: Utc::now(),
            });
        }

        if let Some(rate) = self.mock_rate {
            return Ok(SpotRate {
                rate,
                source: "mock".into(),
                fetched_at: Utc::now(),
            });
        }

        self.ensure_cache().await?;

        let cache = self.cache.read().await;
        let cached = cache.as_ref().expect("cache populated");

        let rate = compute_rate(&from, &to, cached)?;
        Ok(SpotRate {
            rate,
            source: "coingecko+frankfurter".into(),
            fetched_at: Utc::now(),
        })
    }

    async fn ensure_cache(&self) -> Result<(), RateError> {
        {
            let guard = self.cache.read().await;
            if let Some(c) = guard.as_ref() {
                if c.expires_at > std::time::Instant::now() {
                    return Ok(());
                }
            }
        }

        let fiat = fetch_fiat_rates(&self.client).await?;
        let crypto_usd = fetch_crypto_rates(&self.client).await?;

        let mut guard = self.cache.write().await;
        *guard = Some(CachedRates {
            expires_at: std::time::Instant::now() + CACHE_TTL,
            fiat,
            crypto_usd,
        });
        Ok(())
    }
}

fn compute_rate(from: &str, to: &str, cache: &CachedRates) -> Result<f64, RateError> {
    let from_usd = asset_to_usd(from, cache)?;
    let to_usd = asset_to_usd(to, cache)?;
    if from_usd <= 0.0 || to_usd <= 0.0 {
        return Err(RateError::Upstream("invalid zero rate".into()));
    }
    Ok(to_usd / from_usd)
}

fn asset_to_usd(asset: &str, cache: &CachedRates) -> Result<f64, RateError> {
    match asset {
        "USD" => Ok(1.0),
        "EUR" | "GBP" | "CHF" | "CNY" => {
            let table = cache
                .fiat
                .get("USD")
                .ok_or_else(|| RateError::Upstream("USD fiat table missing".into()))?;
            let per_usd = table.get(asset).ok_or_else(|| RateError::UnsupportedPair {
                from: "USD".into(),
                to: asset.into(),
            })?;
            Ok(1.0 / per_usd)
        }
        "USDT" | "USDC" => Ok(cache.crypto_usd.get(asset).copied().unwrap_or(1.0)),
        "BTC" => cache.crypto_usd.get("BTC").copied().ok_or_else(|| RateError::UnsupportedPair {
            from: asset.into(),
            to: "USD".into(),
        }),
        other => Err(RateError::UnsupportedPair {
            from: other.into(),
            to: "USD".into(),
        }),
    }
}

async fn fetch_fiat_rates(
    client: &reqwest::Client,
) -> Result<HashMap<String, HashMap<String, f64>>, RateError> {
    let url = "https://api.frankfurter.app/latest?from=USD";
    let resp: FrankfurterResponse = client
        .get(url)
        .send()
        .await
        .map_err(|e| RateError::Upstream(e.to_string()))?
        .error_for_status()
        .map_err(|e| RateError::Upstream(e.to_string()))?
        .json()
        .await
        .map_err(|e| RateError::Upstream(e.to_string()))?;

    let mut usd_table = HashMap::new();
    usd_table.insert("USD".to_string(), 1.0);
    for (currency, rate) in resp.rates {
        usd_table.insert(currency, rate);
    }

    let mut out = HashMap::new();
    out.insert("USD".to_string(), usd_table);
    Ok(out)
}

async fn fetch_crypto_rates(client: &reqwest::Client) -> Result<HashMap<String, f64>, RateError> {
    let url =
        "https://api.coingecko.com/api/v3/simple/price?ids=tether,usd-coin,bitcoin&vs_currencies=usd";
    let resp: CoinGeckoResponse = client
        .get(url)
        .send()
        .await
        .map_err(|e| RateError::Upstream(e.to_string()))?
        .error_for_status()
        .map_err(|e| RateError::Upstream(e.to_string()))?
        .json()
        .await
        .map_err(|e| RateError::Upstream(e.to_string()))?;

    let mut usd = HashMap::new();

    if let Some(t) = resp.coins.get("tether") {
        if let Some(v) = t.get("usd") {
            usd.insert("USDT".into(), *v);
        }
    }
    if let Some(c) = resp.coins.get("usd-coin") {
        if let Some(v) = c.get("usd") {
            usd.insert("USDC".into(), *v);
        }
    }
    if let Some(b) = resp.coins.get("bitcoin") {
        if let Some(v) = b.get("usd") {
            usd.insert("BTC".into(), *v);
        }
    }

    Ok(usd)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn mock_rate_returns_configured_value() {
        let rates = LiveRates::mock(1.08);
        let spot = rates.spot_rate("USDT", "EUR").await.unwrap();
        assert!((spot.rate - 1.08).abs() < f64::EPSILON);
    }
}
