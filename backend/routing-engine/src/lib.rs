pub mod api;
pub mod assets;
pub mod auth;
pub mod domain;
pub mod engine;
pub mod rates;

use axum::{extract::State, http::StatusCode, Json};
use auth::AuthConfig;
use rates::LiveRates;
use serde::Serialize;

#[derive(Clone)]
pub struct AppState {
    pub rates: LiveRates,
    pub auth: AuthConfig,
}

impl AppState {
    pub fn from_env() -> Self {
        Self {
            rates: LiveRates::new(),
            auth: AuthConfig::from_env(),
        }
    }

    pub fn for_tests() -> Self {
        Self {
            rates: LiveRates::mock(0.92),
            auth: AuthConfig::disabled(),
        }
    }
}

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
    pub version: &'static str,
    pub auth_required: bool,
    pub live_rates: bool,
}

pub async fn health(State(state): State<AppState>) -> (StatusCode, Json<HealthResponse>) {
    (
        StatusCode::OK,
        Json(HealthResponse {
            status: "ok",
            service: "routing-engine",
            version: env!("CARGO_PKG_VERSION"),
            auth_required: state.auth.required,
            live_rates: state.rates.is_live(),
        }),
    )
}
