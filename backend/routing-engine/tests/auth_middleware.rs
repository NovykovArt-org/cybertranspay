use axum::{middleware, routing::post, Router};
use routing_engine::{api, auth, AppState};

#[tokio::test]
async fn rejects_missing_api_key() {
    let state = AppState {
        rates: routing_engine::rates::LiveRates::mock(1.0),
        auth: routing_engine::auth::AuthConfig::for_test("k1"),
    };
    let auth = state.auth.clone();
    let app = Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .route_layer(middleware::from_fn_with_state(auth, auth::require_api_key))
        .with_state(state);

    let response = tower::ServiceExt::oneshot(
        app,
        axum::http::Request::builder()
            .method("POST")
            .uri("/v1/routes/quote")
            .header("content-type", "application/json")
            .body(axum::body::Body::from(
                r#"{"from_asset":"USDT","to_asset":"EUR","amount":10,"preference":"cheapest"}"#,
            ))
            .unwrap(),
    )
    .await
    .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn accepts_valid_api_key() {
    let state = AppState {
        rates: routing_engine::rates::LiveRates::mock(0.92),
        auth: routing_engine::auth::AuthConfig::for_test("secret-key"),
    };
    let auth = state.auth.clone();
    let app = Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .route_layer(middleware::from_fn_with_state(auth, auth::require_api_key))
        .with_state(state);

    let response = tower::ServiceExt::oneshot(
        app,
        axum::http::Request::builder()
            .method("POST")
            .uri("/v1/routes/quote")
            .header("content-type", "application/json")
            .header("x-api-key", "secret-key")
            .body(axum::body::Body::from(
                r#"{"from_asset":"USDT","to_asset":"EUR","amount":100,"preference":"cheapest"}"#,
            ))
            .unwrap(),
    )
    .await
    .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
}
