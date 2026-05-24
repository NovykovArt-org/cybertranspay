pub mod api;
pub mod domain;
pub mod engine;
pub mod rates;

use axum::{extract::State, http::StatusCode, Json};
use rates::LiveRates;
use serde::Serialize;

#[derive(Clone)]
pub struct AppState {
    pub rates: LiveRates,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            rates: LiveRates::new(),
        }
    }
}

impl AppState {
    pub fn for_tests() -> Self {
        Self {
            rates: LiveRates::mock(0.92),
        }
    }
}

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
    pub version: &'static str,
    pub live_rates: bool,
}

pub async fn health(State(state): State<AppState>) -> (StatusCode, Json<HealthResponse>) {
    (
        StatusCode::OK,
        Json(HealthResponse {
            status: "ok",
            service: "routing-engine",
            version: env!("CARGO_PKG_VERSION"),
            live_rates: state.rates.is_live(),
        }),
    )
}
