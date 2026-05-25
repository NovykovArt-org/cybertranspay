use crate::domain::QuoteResponse;
use chrono::{DateTime, Duration, Utc};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Clone, Debug)]
pub struct StoredQuote {
    pub quote_id: String,
    pub expires_at: DateTime<Utc>,
    pub response: QuoteResponse,
}

#[derive(Clone)]
pub struct QuoteStore {
    inner: Arc<RwLock<HashMap<String, StoredQuote>>>,
    ttl: Duration,
}

impl QuoteStore {
    pub fn from_env() -> Self {
        let secs = std::env::var("QUOTE_TTL_SECS")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(300);
        Self::with_ttl(Duration::seconds(secs as i64))
    }

    pub fn with_ttl(ttl: Duration) -> Self {
        Self {
            inner: Arc::new(RwLock::new(HashMap::new())),
            ttl,
        }
    }

    pub fn ttl(&self) -> Duration {
        self.ttl
    }

    pub async fn insert(&self, mut response: QuoteResponse) -> StoredQuote {
        let quote_id = Uuid::new_v4().to_string();
        let expires_at = Utc::now() + self.ttl;
        response.quote_id = quote_id.clone();
        response.expires_at = expires_at;

        let stored = StoredQuote {
            quote_id: quote_id.clone(),
            expires_at,
            response: response.clone(),
        };

        self.inner.write().await.insert(quote_id, stored.clone());
        stored
    }

    pub async fn get(&self, quote_id: &str) -> Option<StoredQuote> {
        let mut guard = self.inner.write().await;
        let stored = guard.get(quote_id)?.clone();
        if stored.expires_at <= Utc::now() {
            guard.remove(quote_id);
            return None;
        }
        Some(stored)
    }
}
