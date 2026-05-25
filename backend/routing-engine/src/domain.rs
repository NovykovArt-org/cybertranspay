use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum RoutePreference {
    #[default]
    Cheapest,
    Fastest,
    Compliant,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuoteRequest {
    pub from_asset: String,
    pub to_asset: String,
    pub amount: f64,
    #[serde(default)]
    pub preference: RoutePreference,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RouteQuote {
    pub route_id: String,
    pub label: String,
    pub rails: Vec<String>,
    pub fee_percent: f64,
    pub eta_minutes: u32,
    pub compliance_score: u8,
    pub spot_rate: f64,
    pub estimated_receive: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuoteResponse {
    pub quote_id: String,
    pub expires_at: DateTime<Utc>,
    pub request: QuoteRequest,
    pub routes: Vec<RouteQuote>,
    pub selected_preference: RoutePreference,
    pub spot_rate: f64,
    pub rate_source: String,
    pub live_pricing: bool,
    pub priced_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CreateTransferRequest {
    pub quote_id: String,
    pub route_id: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TransferStatus {
    Completed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransferResponse {
    pub transfer_id: String,
    pub quote_id: String,
    pub route_id: String,
    pub from_asset: String,
    pub to_asset: String,
    pub amount: f64,
    pub estimated_receive: f64,
    pub status: TransferStatus,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SpotRateQuery {
    pub from: String,
    pub to: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct SpotRateResponse {
    pub from_asset: String,
    pub to_asset: String,
    pub rate: f64,
    pub rate_source: String,
    pub live_pricing: bool,
    pub priced_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct AssetsResponse {
    pub assets: Vec<crate::assets::AssetInfo>,
}
