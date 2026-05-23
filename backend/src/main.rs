use axum::{
    routing::get,
    Router,
    Json,
    extract::WebSocketUpgrade,
    response::IntoResponse,
};
use serde::{Deserialize, Serialize};
use petgraph::graph::{Graph, NodeIndex};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PaymentIntent {
    pub amount: f64,
    pub from_currency: String,
    pub to_currency: String,
    pub from_country: String,
    pub to_country: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Route {
    pub path: String,
    pub cost: f64,
    pub time_seconds: u64,
    pub compliance_score: f64,
    pub total_score: f64,
}

#[derive(Debug, Clone)]
pub struct RoutingEngine {
    graph: Graph<String, f64>,
    nodes: HashMap<String, NodeIndex>,
}

impl RoutingEngine {
    pub fn new() -> Self {
        let mut engine = RoutingEngine {
            graph: Graph::new(),
            nodes: HashMap::new(),
        };
        engine.init_default_rails();
        engine
    }

    fn init_default_rails(&mut self) {
        let rails = vec!["USDC", "SEPA", "SWIFT", "BRICS", "LayerZero", "CIPS", "Pix", "SBP"];

        for rail in &rails {
            let idx = self.graph.add_node(rail.to_string());
            self.nodes.insert(rail.to_string(), idx);
        }

        self.add_connection("USDC", "LayerZero", 0.5, 8, 0.95);
        self.add_connection("USDC", "SEPA", 1.2, 45, 0.98);
        self.add_connection("BRICS", "CIPS", 0.3, 120, 0.99);
        self.add_connection("SBP", "USDC", 0.8, 25, 0.85);
    }

    fn add_connection(&mut self, from: &str, to: &str, cost: f64, time: u64, compliance: f64) {
        if let (Some(&from_idx), Some(&to_idx)) = (self.nodes.get(from), self.nodes.get(to)) {
            self.graph.add_edge(from_idx, to_idx, cost);
        }
    }

    pub fn find_best_routes(&self, intent: &PaymentIntent) -> Vec<Route> {
        let mut routes = vec![];

        routes.push(Route {
            path: "USDC → LayerZero → Target".to_string(),
            cost: 0.8,
            time_seconds: 12,
            compliance_score: 0.94,
            total_score: 0.0,
        });

        routes.push(Route {
            path: "Local Rail → BRICS Bridge".to_string(),
            cost: 0.4,
            time_seconds: 180,
            compliance_score: 0.99,
            total_score: 0.0,
        });

        for route in &mut routes {
            let cost_score = 1.0 / (1.0 + route.cost);
            let time_score = 1.0 / (1.0 + (route.time_seconds as f64 / 60.0));
            route.total_score = (cost_score * 0.4) + (time_score * 0.3) + (route.compliance_score * 0.3);
        }

        routes.sort_by(|a, b| b.total_score.partial_cmp(&a.total_score).unwrap());
        routes
    }
}

#[tokio::main]
async fn main() {
    env_logger::init();
    let engine = RoutingEngine::new();

    println!("🚀 CyberTransPay Routing Engine v0.1.0 started!");
    println!("Server running on http://0.0.0.0:8080");

    let app = Router::new()
        .route("/", get(root_handler))
        .route("/route", get({
            let engine = engine.clone();
            move || {
                let engine = engine.clone();
                async move {
                    let intent = PaymentIntent {
                        amount: 1000.0,
                        from_currency: "USD".to_string(),
                        to_currency: "EUR".to_string(),
                        from_country: "US".to_string(),
                        to_country: "DE".to_string(),
                    };
                    let routes = engine.find_best_routes(&intent);
                    Json(routes)
                }
            }
        }))
        .route("/health", get(health_check));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn root_handler() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "service": "cybertranspay-routing-engine",
        "status": "running",
        "version": "0.1.0"
    }))
}

async fn health_check() -> Json<serde_json::Value> {
    Json(serde_json::json!({ "status": "healthy" }))
}
