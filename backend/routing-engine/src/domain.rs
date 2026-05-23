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
    pub estimated_receive: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuoteResponse {
    pub request: QuoteRequest,
    pub routes: Vec<RouteQuote>,
    pub selected_preference: RoutePreference,
}
