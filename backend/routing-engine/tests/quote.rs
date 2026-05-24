use axum::{routing::post, Router};
use http_body_util::BodyExt;
use routing_engine::{api, AppState};
use tower::ServiceExt;

#[tokio::test]
async fn quote_returns_ranked_routes() {
    let app = Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .with_state(AppState::for_tests());

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
    assert_eq!(json["live_pricing"], false);
}

#[tokio::test]
async fn quote_rejects_invalid_amount() {
    let app = Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .with_state(AppState::for_tests());

    let body = r#"{"from_asset":"USDT","to_asset":"EUR","amount":0,"preference":"cheapest"}"#;
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

    assert_eq!(response.status(), axum::http::StatusCode::BAD_REQUEST);
}
