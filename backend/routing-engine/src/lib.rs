use axum::{http::StatusCode, Json};
use serde::Serialize;

#[derive(Clone, Default)]
pub struct AppState;

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
}

pub async fn health() -> (StatusCode, Json<HealthResponse>) {
    (
        StatusCode::OK,
        Json(HealthResponse {
            status: "ok",
            service: "routing-engine",
        }),
    )
}
