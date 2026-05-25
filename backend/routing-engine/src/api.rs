use crate::assets::{self, AssetInfo};
use crate::domain::{
    AssetsResponse, CreateTransferRequest, QuoteRequest, QuoteResponse, SpotRateQuery,
    SpotRateResponse, TransferResponse,
};
use crate::engine;
use crate::rates::RateError;
use crate::transfers::TransferError;
use crate::AppState;
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use chrono::Utc;
use serde::Serialize;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("invalid request: {0}")]
    BadRequest(String),
    #[error("not found: {0}")]
    NotFound(String),
    #[error("rate lookup failed: {0}")]
    RateUnavailable(String),
}

#[derive(Serialize)]
struct ErrorBody {
    error: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match &self {
            ApiError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            ApiError::NotFound(msg) => (StatusCode::NOT_FOUND, msg.clone()),
            ApiError::RateUnavailable(msg) => (StatusCode::SERVICE_UNAVAILABLE, msg.clone()),
        };
        (status, Json(ErrorBody { error: message })).into_response()
    }
}

impl From<RateError> for ApiError {
    fn from(err: RateError) -> Self {
        match err {
            RateError::UnsupportedPair { .. } => ApiError::BadRequest(err.to_string()),
            RateError::Upstream(msg) => ApiError::RateUnavailable(msg),
        }
    }
}

impl From<TransferError> for ApiError {
    fn from(err: TransferError) -> Self {
        ApiError::BadRequest(err.to_string())
    }
}

pub async fn list_assets() -> Json<AssetsResponse> {
    let assets: Vec<AssetInfo> = assets::supported_assets().iter().copied().collect();
    Json(AssetsResponse { assets })
}

pub async fn spot_rate(
    State(state): State<AppState>,
    Query(query): Query<SpotRateQuery>,
) -> Result<Json<SpotRateResponse>, ApiError> {
    if query.from.trim().is_empty() || query.to.trim().is_empty() {
        return Err(ApiError::BadRequest(
            "query params 'from' and 'to' are required".into(),
        ));
    }

    let from = query.from.trim().to_uppercase();
    let to = query.to.trim().to_uppercase();

    if !assets::is_supported(&from) || !assets::is_supported(&to) {
        return Err(ApiError::BadRequest(
            "unsupported asset; use GET /v1/assets for supported codes".into(),
        ));
    }

    let spot = state.rates.spot_rate(&from, &to).await?;

    Ok(Json(SpotRateResponse {
        from_asset: from,
        to_asset: to,
        rate: spot.rate,
        rate_source: spot.source,
        live_pricing: state.rates.is_live(),
        priced_at: spot.fetched_at,
    }))
}

pub async fn quote_routes(
    State(state): State<AppState>,
    Json(request): Json<QuoteRequest>,
) -> Result<Json<QuoteResponse>, ApiError> {
    if !request.amount.is_finite() || request.amount <= 0.0 {
        return Err(ApiError::BadRequest(
            "amount must be greater than zero".into(),
        ));
    }
    if request.from_asset.trim().is_empty() || request.to_asset.trim().is_empty() {
        return Err(ApiError::BadRequest(
            "from_asset and to_asset are required".into(),
        ));
    }

    let from = request.from_asset.trim().to_uppercase();
    let to = request.to_asset.trim().to_uppercase();

    if !assets::is_supported(&from) || !assets::is_supported(&to) {
        return Err(ApiError::BadRequest(
            "unsupported asset; use GET /v1/assets for supported codes".into(),
        ));
    }

    let spot = state.rates.spot_rate(&from, &to).await?;

    let preference = request.preference;
    let mut request = request;
    request.from_asset = from;
    request.to_asset = to;

    let routes = engine::quote(&request, spot.rate);

    let response = QuoteResponse {
        quote_id: String::new(),
        expires_at: Utc::now(),
        request,
        routes,
        selected_preference: preference,
        spot_rate: spot.rate,
        rate_source: spot.source,
        live_pricing: state.rates.is_live(),
        priced_at: spot.fetched_at,
    };

    let stored = state.quotes.insert(response).await;
    Ok(Json(stored.response))
}

pub async fn get_quote(
    State(state): State<AppState>,
    Path(quote_id): Path<String>,
) -> Result<Json<QuoteResponse>, ApiError> {
    let stored = state
        .quotes
        .get(&quote_id)
        .await
        .ok_or_else(|| ApiError::NotFound(format!("quote '{quote_id}' not found or expired")))?;
    Ok(Json(stored.response))
}

pub async fn create_transfer(
    State(state): State<AppState>,
    Json(body): Json<CreateTransferRequest>,
) -> Result<Json<TransferResponse>, ApiError> {
    if body.quote_id.trim().is_empty() || body.route_id.trim().is_empty() {
        return Err(ApiError::BadRequest(
            "quote_id and route_id are required".into(),
        ));
    }

    let quote = state
        .quotes
        .get(body.quote_id.trim())
        .await
        .ok_or_else(|| {
            ApiError::NotFound(format!(
                "quote '{}' not found or expired",
                body.quote_id.trim()
            ))
        })?;

    let transfer = state
        .transfers
        .create_from_quote(&quote.response, body.route_id.trim())
        .await?;

    Ok(Json(transfer))
}

pub async fn get_transfer(
    State(state): State<AppState>,
    Path(transfer_id): Path<String>,
) -> Result<Json<TransferResponse>, ApiError> {
    let transfer = state
        .transfers
        .get(&transfer_id)
        .await
        .ok_or_else(|| {
            ApiError::NotFound(format!("transfer '{transfer_id}' not found"))
        })?;
    Ok(Json(transfer))
}
