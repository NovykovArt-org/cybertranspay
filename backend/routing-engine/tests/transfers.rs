use axum::{
    routing::{get, post},
    Router,
};
use http_body_util::BodyExt;
use routing_engine::{api, AppState};
use std::path::PathBuf;
use tower::ServiceExt;

fn app(state: AppState) -> Router {
    Router::new()
        .route("/v1/routes/quote", post(api::quote_routes))
        .route("/v1/quotes/:quote_id", get(api::get_quote))
        .route("/v1/transfers", post(api::create_transfer))
        .route("/v1/transfers/:transfer_id", get(api::get_transfer))
        .with_state(state)
}

async fn create_quote(app: &Router) -> serde_json::Value {
    let body = r#"{"from_asset":"USDT","to_asset":"EUR","amount":1000,"preference":"cheapest"}"#;
    let response = app
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

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    serde_json::from_slice(&bytes).unwrap()
}

#[tokio::test]
async fn get_quote_returns_stored_quote() {
    let app = app(AppState::for_tests());
    let quote = create_quote(&app).await;
    let quote_id = quote["quote_id"].as_str().unwrap();

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri(format!("/v1/quotes/{quote_id}"))
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(json["quote_id"], quote_id);
    assert_eq!(json["spot_rate"], 0.92);
}

#[tokio::test]
async fn get_quote_returns_not_found_for_unknown_id() {
    let app = app(AppState::for_tests());

    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri("/v1/quotes/does-not-exist")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn create_transfer_from_quote() {
    let app = app(AppState::for_tests());
    let quote = create_quote(&app).await;
    let quote_id = quote["quote_id"].as_str().unwrap();
    let route_id = quote["routes"][0]["route_id"].as_str().unwrap();

    let body = format!(r#"{{"quote_id":"{quote_id}","route_id":"{route_id}"}}"#);
    let response = app
        .clone()
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/transfers")
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let json: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(json["quote_id"], quote_id);
    assert_eq!(json["route_id"], route_id);
    assert_eq!(json["status"], "completed");
    assert!(json["transfer_id"].as_str().unwrap().len() > 0);

    let transfer_id = json["transfer_id"].as_str().unwrap();
    let response = app
        .oneshot(
            axum::http::Request::builder()
                .uri(format!("/v1/transfers/{transfer_id}"))
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::OK);
}

#[tokio::test]
async fn create_transfer_rejects_unknown_route() {
    let app = app(AppState::for_tests());
    let quote = create_quote(&app).await;
    let quote_id = quote["quote_id"].as_str().unwrap();

    let body = format!(r#"{{"quote_id":"{quote_id}","route_id":"unknown-route"}}"#);
    let response = app
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/transfers")
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn create_transfer_rejects_expired_quote() {
    let state = AppState {
        rates: routing_engine::rates::LiveRates::mock(0.92),
        auth: routing_engine::auth::AuthConfig::disabled(),
        quotes: routing_engine::quotes::QuoteStore::with_ttl(chrono::Duration::seconds(1)),
        transfers: routing_engine::transfers::TransferStore::new(),
    };
    let router = app(state);
    let quote = create_quote(&router).await;
    let quote_id = quote["quote_id"].as_str().unwrap();
    let route_id = quote["routes"][0]["route_id"].as_str().unwrap();

    tokio::time::sleep(std::time::Duration::from_secs(2)).await;

    let body = format!(r#"{{"quote_id":"{quote_id}","route_id":"{route_id}"}}"#);
    let response = router
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/transfers")
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), axum::http::StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn quotes_and_transfers_persist_to_disk() {
    let dir = temp_store_dir();
    let quote_path = dir.join("quotes.json");
    let transfer_path = dir.join("transfers.json");

    let state = AppState {
        rates: routing_engine::rates::LiveRates::mock(0.92),
        auth: routing_engine::auth::AuthConfig::disabled(),
        quotes: routing_engine::quotes::QuoteStore::with_ttl_and_path(
            chrono::Duration::minutes(5),
            Some(quote_path.clone()),
        ),
        transfers: routing_engine::transfers::TransferStore::with_path(Some(transfer_path.clone())),
    };
    let router = app(state);
    let quote = create_quote(&router).await;
    let quote_id = quote["quote_id"].as_str().unwrap();
    let route_id = quote["routes"][0]["route_id"].as_str().unwrap();

    let body = format!(r#"{{"quote_id":"{quote_id}","route_id":"{route_id}"}}"#);
    let response = router
        .oneshot(
            axum::http::Request::builder()
                .method("POST")
                .uri("/v1/transfers")
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), axum::http::StatusCode::OK);
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let transfer: serde_json::Value = serde_json::from_slice(&bytes).unwrap();
    let transfer_id = transfer["transfer_id"].as_str().unwrap();

    let restored_state = AppState {
        rates: routing_engine::rates::LiveRates::mock(0.92),
        auth: routing_engine::auth::AuthConfig::disabled(),
        quotes: routing_engine::quotes::QuoteStore::with_ttl_and_path(
            chrono::Duration::minutes(5),
            Some(quote_path),
        ),
        transfers: routing_engine::transfers::TransferStore::with_path(Some(transfer_path)),
    };
    let restored_app = app(restored_state);

    let response = restored_app
        .clone()
        .oneshot(
            axum::http::Request::builder()
                .uri(format!("/v1/quotes/{quote_id}"))
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), axum::http::StatusCode::OK);

    let response = restored_app
        .oneshot(
            axum::http::Request::builder()
                .uri(format!("/v1/transfers/{transfer_id}"))
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), axum::http::StatusCode::OK);

    let _ = std::fs::remove_dir_all(dir);
}

fn temp_store_dir() -> PathBuf {
    let unique = format!(
        "routing-engine-persistence-{}-{}",
        std::process::id(),
        chrono::Utc::now().timestamp_nanos_opt().unwrap()
    );
    let dir = std::env::temp_dir().join(unique);
    std::fs::create_dir_all(&dir).unwrap();
    dir
}
