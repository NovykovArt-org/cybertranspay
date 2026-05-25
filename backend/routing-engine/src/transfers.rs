use crate::domain::{QuoteResponse, TransferResponse, TransferStatus};
use chrono::Utc;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

#[derive(Clone)]
pub struct TransferStore {
    inner: Arc<RwLock<HashMap<String, TransferResponse>>>,
}

impl TransferStore {
    pub fn new() -> Self {
        Self {
            inner: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub async fn create_from_quote(
        &self,
        quote: &QuoteResponse,
        route_id: &str,
    ) -> Result<TransferResponse, TransferError> {
        let route = quote
            .routes
            .iter()
            .find(|r| r.route_id == route_id)
            .ok_or(TransferError::RouteNotInQuote {
                route_id: route_id.into(),
            })?;

        let transfer = TransferResponse {
            transfer_id: Uuid::new_v4().to_string(),
            quote_id: quote.quote_id.clone(),
            route_id: route.route_id.clone(),
            from_asset: quote.request.from_asset.to_uppercase(),
            to_asset: quote.request.to_asset.to_uppercase(),
            amount: quote.request.amount,
            estimated_receive: route.estimated_receive,
            status: TransferStatus::Completed,
            created_at: Utc::now(),
        };

        self.inner
            .write()
            .await
            .insert(transfer.transfer_id.clone(), transfer.clone());
        Ok(transfer)
    }

    pub async fn get(&self, transfer_id: &str) -> Option<TransferResponse> {
        self.inner.read().await.get(transfer_id).cloned()
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
