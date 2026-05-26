use crate::domain::QuoteResponse;
use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct StoredQuote {
    pub quote_id: String,
    pub expires_at: DateTime<Utc>,
    pub response: QuoteResponse,
}

#[derive(Clone)]
pub struct QuoteStore {
    inner: Arc<RwLock<HashMap<String, StoredQuote>>>,
    ttl: Duration,
    path: Option<Arc<PathBuf>>,
}

impl QuoteStore {
    pub fn from_env() -> Self {
        let secs = std::env::var("QUOTE_TTL_SECS")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(300);
        Self::with_ttl_and_path(
            Duration::seconds(secs as i64),
            persistence_path("QUOTE_STORE_PATH", "quotes.json"),
        )
    }

    pub fn with_ttl(ttl: Duration) -> Self {
        Self::with_ttl_and_path(ttl, None)
    }

    pub fn with_ttl_and_path(ttl: Duration, path: Option<PathBuf>) -> Self {
        let quotes = path
            .as_deref()
            .map(load_quotes)
            .unwrap_or_else(HashMap::new);
        Self {
            inner: Arc::new(RwLock::new(quotes)),
            ttl,
            path: path.map(Arc::new),
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

        let snapshot = {
            let mut guard = self.inner.write().await;
            guard.insert(quote_id, stored.clone());
            guard.clone()
        };
        self.persist(&snapshot);
        stored
    }

    pub async fn get(&self, quote_id: &str) -> Option<StoredQuote> {
        let (stored, snapshot) = {
            let mut guard = self.inner.write().await;
            let stored = guard.get(quote_id)?.clone();
            if stored.expires_at <= Utc::now() {
                guard.remove(quote_id);
                (None, Some(guard.clone()))
            } else {
                (Some(stored), None)
            }
        };
        if let Some(snapshot) = snapshot {
            self.persist(&snapshot);
        }
        stored
    }

    fn persist(&self, quotes: &HashMap<String, StoredQuote>) {
        let Some(path) = self.path.as_deref() else {
            return;
        };
        if let Err(err) = write_json(path, quotes) {
            tracing::warn!(path = %path.display(), error = %err, "failed to persist quotes");
        }
    }
}

fn persistence_path(var_name: &str, file_name: &str) -> Option<PathBuf> {
    if let Ok(path) = std::env::var(var_name) {
        return Some(PathBuf::from(path));
    }
    std::env::var("CTP_DATA_DIR")
        .ok()
        .map(|dir| PathBuf::from(dir).join(file_name))
}

fn load_quotes(path: &Path) -> HashMap<String, StoredQuote> {
    match std::fs::read_to_string(path) {
        Ok(contents) => serde_json::from_str(&contents).unwrap_or_else(|err| {
            tracing::warn!(path = %path.display(), error = %err, "failed to parse quotes store");
            HashMap::new()
        }),
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => HashMap::new(),
        Err(err) => {
            tracing::warn!(path = %path.display(), error = %err, "failed to read quotes store");
            HashMap::new()
        }
    }
}

fn write_json<T: Serialize>(path: &Path, value: &T) -> std::io::Result<()> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let bytes = serde_json::to_vec_pretty(value)
        .map_err(|err| std::io::Error::new(std::io::ErrorKind::InvalidData, err))?;
    std::fs::write(path, bytes)
}
