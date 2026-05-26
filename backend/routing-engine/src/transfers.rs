use crate::domain::{QuoteResponse, TransferResponse, TransferStatus};
use chrono::{Duration, Utc};
use serde::Serialize;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Clone)]
pub struct TransferStore {
    inner: Arc<RwLock<HashMap<String, TransferResponse>>>,
    path: Option<Arc<PathBuf>>,
    processing_after: Duration,
    completion_after: Duration,
}

impl TransferStore {
    pub fn new() -> Self {
        Self::with_path(None)
    }

    pub fn from_env() -> Self {
        Self::with_lifecycle(
            persistence_path("TRANSFER_STORE_PATH", "transfers.json"),
            duration_from_env("TRANSFER_PROCESSING_DELAY_MS", 750),
            duration_from_env("TRANSFER_COMPLETION_DELAY_MS", 1_500),
        )
    }

    pub fn with_path(path: Option<PathBuf>) -> Self {
        Self::with_lifecycle(
            path,
            Duration::milliseconds(750),
            Duration::milliseconds(1_500),
        )
    }

    pub fn with_lifecycle(
        path: Option<PathBuf>,
        processing_after: Duration,
        completion_after: Duration,
    ) -> Self {
        let transfers = path
            .as_deref()
            .map(load_transfers)
            .unwrap_or_else(HashMap::new);
        Self {
            inner: Arc::new(RwLock::new(transfers)),
            path: path.map(Arc::new),
            processing_after,
            completion_after,
        }
    }

    pub async fn create_from_quote(
        &self,
        quote: &QuoteResponse,
        route_id: &str,
    ) -> Result<TransferResponse, TransferError> {
        let route = quote.routes.iter().find(|r| r.route_id == route_id).ok_or(
            TransferError::RouteNotInQuote {
                route_id: route_id.into(),
            },
        )?;

        let transfer = TransferResponse {
            transfer_id: Uuid::new_v4().to_string(),
            quote_id: quote.quote_id.clone(),
            route_id: route.route_id.clone(),
            from_asset: quote.request.from_asset.to_uppercase(),
            to_asset: quote.request.to_asset.to_uppercase(),
            amount: quote.request.amount,
            estimated_receive: route.estimated_receive,
            status: TransferStatus::Pending,
            created_at: Utc::now(),
        };

        let snapshot = {
            let mut guard = self.inner.write().await;
            guard.insert(transfer.transfer_id.clone(), transfer.clone());
            guard.clone()
        };
        self.persist(&snapshot);
        Ok(transfer)
    }

    pub async fn get(&self, transfer_id: &str) -> Option<TransferResponse> {
        let (transfer, snapshot) = {
            let mut guard = self.inner.write().await;
            let transfer = guard.get_mut(transfer_id)?;
            let next_status = self.status_for(transfer);
            if next_status != transfer.status {
                transfer.status = next_status;
                (transfer.clone(), Some(guard.clone()))
            } else {
                (transfer.clone(), None)
            }
        };
        if let Some(snapshot) = snapshot {
            self.persist(&snapshot);
        }
        Some(transfer)
    }

    fn persist(&self, transfers: &HashMap<String, TransferResponse>) {
        let Some(path) = self.path.as_deref() else {
            return;
        };
        if let Err(err) = write_json(path, transfers) {
            tracing::warn!(path = %path.display(), error = %err, "failed to persist transfers");
        }
    }

    fn status_for(&self, transfer: &TransferResponse) -> TransferStatus {
        if matches!(
            transfer.status,
            TransferStatus::Completed | TransferStatus::Failed
        ) {
            return transfer.status;
        }

        let elapsed = Utc::now() - transfer.created_at;
        if elapsed >= self.completion_after {
            TransferStatus::Completed
        } else if elapsed >= self.processing_after {
            TransferStatus::Processing
        } else {
            TransferStatus::Pending
        }
    }
}

impl Default for TransferStore {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TransferError {
    RouteNotInQuote { route_id: String },
}

impl std::fmt::Display for TransferError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TransferError::RouteNotInQuote { route_id } => {
                write!(f, "route_id '{route_id}' is not part of the quote")
            }
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

fn duration_from_env(var_name: &str, default_ms: i64) -> Duration {
    let millis = std::env::var(var_name)
        .ok()
        .and_then(|value| value.parse::<i64>().ok())
        .unwrap_or(default_ms)
        .max(0);
    Duration::milliseconds(millis)
}

fn load_transfers(path: &Path) -> HashMap<String, TransferResponse> {
    match std::fs::read_to_string(path) {
        Ok(contents) => serde_json::from_str(&contents).unwrap_or_else(|err| {
            tracing::warn!(path = %path.display(), error = %err, "failed to parse transfers store");
            HashMap::new()
        }),
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => HashMap::new(),
        Err(err) => {
            tracing::warn!(path = %path.display(), error = %err, "failed to read transfers store");
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
