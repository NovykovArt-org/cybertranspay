use crate::domain::{QuoteRequest, QuoteResponse};
use crate::engine;
use crate::AppState;
use axum::{
    extract::State,
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
}

#[derive(Serialize)]
struct ErrorBody {
    error: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            ApiError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg),
        };
        (status, Json(ErrorBody { error: message })).into_response()
    }
}

pub async fn quote_routes(
    State(_state): State<AppState>,
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

    let preference = request.preference;
    let routes = engine::quote(&request);

    Ok(Json(QuoteResponse {
        request,
        routes,
        selected_preference: preference,
    }))
}
