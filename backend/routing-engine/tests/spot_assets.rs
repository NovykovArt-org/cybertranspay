use axum::{middleware, routing::get, Router};
use http_body_util::BodyExt;
use routing_engine::{api, auth, AppState};
use tower::ServiceExt;

fn protected_app(state: AppState) -> Router {
    let auth = state.auth.clone();
    Router::new()
        .route("/v1/assets", get(api::list_assets))
        .route("/v1/rates/spot", get(api::spot_rate))
        .route_layer(middleware::from_fn_with_state(auth, auth::require_api_key))
        .with_state(state)
}

#[tokio::test]
async fn assets_lists_supported_codes() {
    let app = protected_app(AppState::for_tests());

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/v1/assets")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    let codes: Vec<_> = json["assets"]
        .as_array()
        .unwrap()
        .iter()
        .map(|a| a["code"].as_str().unwrap())
        .collect();
    assert!(codes.contains(&"USDT"));
    assert!(codes.contains(&"EUR"));
    assert_eq!(codes.len(), 14);
}

#[tokio::test]
async fn spot_rate_returns_mock_rate() {
    let app = protected_app(AppState::for_tests());

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/v1/rates/spot?from=USDT&to=EUR")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(json["from_asset"], "USDT");
    assert_eq!(json["to_asset"], "EUR");
    assert_eq!(json["rate"], 0.92);
    assert_eq!(json["rate_source"], "mock");
}

#[tokio::test]
async fn spot_rate_rejects_unknown_asset() {
    let app = protected_app(AppState::for_tests());

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/v1/rates/spot?from=XYZ&to=EUR")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn assets_requires_api_key_when_auth_enabled() {
    let state = AppState {
        rates: routing_engine::rates::LiveRates::mock(1.0),
        auth: routing_engine::auth::AuthConfig::for_test("secret"),
        quotes: routing_engine::quotes::QuoteStore::with_ttl(chrono::Duration::minutes(5)),
        transfers: routing_engine::transfers::TransferStore::new(),
    };
    let app = protected_app(state);

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/v1/assets")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::UNAUTHORIZED);
}
