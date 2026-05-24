use crate::assets::{self, AssetInfo};
use crate::domain::{AssetsResponse, QuoteRequest, QuoteResponse, SpotRateQuery, SpotRateResponse};
use crate::engine;
use crate::rates::RateError;
use crate::AppState;
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("invalid request: {0}")]
    BadRequest(String),
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
        return Err(ApiError::BadRequest(format!(
            "unsupported asset; use GET /v1/assets for supported codes"
        )));
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

    let spot = state.rates.spot_rate(&request.from_asset, &request.to_asset).await?;

    let preference = request.preference;
    let routes = engine::quote(&request, spot.rate);

    Ok(Json(QuoteResponse {
        request,
        routes,
        selected_preference: preference,
        spot_rate: spot.rate,
        rate_source: spot.source,
        live_pricing: state.rates.is_live(),
        priced_at: spot.fetched_at,
    }))
}
