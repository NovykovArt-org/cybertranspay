use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::sync::Arc;

#[derive(Clone)]
pub struct AuthConfig {
    pub required: bool,
    keys: Arc<Vec<String>>,
}

impl AuthConfig {
    pub fn from_env() -> Self {
        let required = std::env::var("AUTH_REQUIRED")
            .map(|v| v == "true" || v == "1")
            .unwrap_or(false);

        let keys: Vec<String> = std::env::var("AUTH_API_KEYS")
            .ok()
            .map(|raw| {
                raw.split(',')
                    .map(str::trim)
                    .filter(|k| !k.is_empty())
                    .map(ToString::to_string)
                    .collect()
            })
            .unwrap_or_default();

        if required && keys.is_empty() {
            tracing::warn!("AUTH_REQUIRED=true but AUTH_API_KEYS is empty");
        }

        Self {
            required,
            keys: Arc::new(keys),
        }
    }

    pub fn disabled() -> Self {
        Self {
            required: false,
            keys: Arc::new(Vec::new()),
        }
    }

    pub fn for_test(key: &str) -> Self {
        Self {
            required: true,
            keys: Arc::new(vec![key.to_string()]),
        }
    }

    fn is_valid(&self, key: &str) -> bool {
        self.keys.iter().any(|k| k == key)
    }
}

#[derive(Serialize)]
struct AuthError {
    error: String,
}

pub async fn require_api_key(
    State(auth): State<AuthConfig>,
    request: Request,
    next: Next,
) -> Response {
    if !auth.required {
        return next.run(request).await;
    }

    let provided = request
        .headers()
        .get("x-api-key")
        .and_then(|v| v.to_str().ok());

    match provided {
        Some(key) if auth.is_valid(key) => next.run(request).await,
        _ => (
            StatusCode::UNAUTHORIZED,
            Json(AuthError {
                error: "missing or invalid X-API-Key".into(),
            }),
        )
            .into_response(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disabled_auth_accepts_any_key_check() {
        let auth = AuthConfig::disabled();
        assert!(!auth.required);
    }

    #[test]
    fn for_test_validates_key() {
        let auth = AuthConfig::for_test("secret");
        assert!(auth.is_valid("secret"));
        assert!(!auth.is_valid("wrong"));
    }
}
