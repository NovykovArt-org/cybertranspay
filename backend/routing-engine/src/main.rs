use axum::{routing::get, Json, Router};
use routing_engine::{health, AppState};
use std::net::SocketAddr;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let state = AppState::default();
    let app = Router::new()
        .route("/health", get(health))
        .route("/v1/routes/quote", get(quote_placeholder))
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    tracing::info!("routing-engine listening on {addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.expect("bind");
    axum::serve(listener, app).await.expect("serve");
}

async fn quote_placeholder() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "pre-mvp",
        "message": "Routing quotes will be available in MVP release"
    }))
}
