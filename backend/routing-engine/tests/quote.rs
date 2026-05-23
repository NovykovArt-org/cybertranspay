use axum::{middleware, routing::post, Router};
use http_body_util::BodyExt;
use routing_engine::{api, auth, AppState};
use tower::ServiceExt;

#[tokio::test]
async fn quote_returns_ranked_routes() {
    let state = AppState::for_tests();
    let auth = state.auth.clone();
    let app = Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .route_layer(middleware::from_fn_with_state(auth, auth::require_api_key))
        .with_state(state);

    let body = r#"{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}"#;
    let response = app
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/routes/quote")
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    assert!(json["routes"].as_array().unwrap().len() > 0);
    assert_eq!(json["spot_rate"], 0.92);
    assert_eq!(json["rate_source"], "mock");
}

#[tokio::test]
async fn quote_requires_api_key_when_auth_enabled() {
    let state = AppState {
        rates: routing_engine::rates::LiveRates::mock(1.0),
        auth: routing_engine::auth::AuthConfig::for_test("secret-test-key"),
    };
    let auth = state.auth.clone();
    let app = Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .route_layer(middleware::from_fn_with_state(auth, auth::require_api_key))
        .with_state(state);

    let body = r#"{"from_asset":"USDT","to_asset":"EUR","amount":100,"preference":"fastest"}"#;
    let unauthorized = app
        .clone()
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/routes/quote")
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(unauthorized.status(), axum::http::StatusCode::UNAUTHORIZED);

    let ok = app
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/routes/quote")
                .header("content-type", "application/json")
                .header("x-api-key", "secret-test-key")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(ok.status(), axum::http::StatusCode::OK);
}
