use axum::{routing::get, Router};
use http_body_util::BodyExt;
use routing_engine::{health, AppState};
use tower::ServiceExt;

#[tokio::test]
async fn health_returns_ok() {
    let app = Router::new()
        .route("/health", get(health))
        .with_state(AppState::default());

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/health")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let body = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert_eq!(json["status"], "ok");
    assert_eq!(json["service"], "routing-engine");
}
