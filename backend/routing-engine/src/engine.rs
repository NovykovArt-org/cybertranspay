use crate::domain::{QuoteRequest, RoutePreference, RouteQuote};

struct RouteCandidate {
    route_id: &'static str,
    label: &'static str,
    rails: &'static [&'static str],
    from_assets: &'static [&'static str],
    to_assets: &'static [&'static str],
    fee_percent: f64,
    eta_minutes: u32,
    compliance_score: u8,
}

const CATALOG: &[RouteCandidate] = &[
    RouteCandidate {
        route_id: "bank-sepa",
        label: "SEPA bank rail",
        rails: &["fiat", "bank"],
        from_assets: &["EUR", "USD"],
        to_assets: &["EUR", "USD"],
        fee_percent: 0.35,
        eta_minutes: 1440,
        compliance_score: 95,
    },
    RouteCandidate {
        route_id: "stablecoin-tron",
        label: "USDT TRC-20 corridor",
        rails: &["crypto", "stablecoin"],
        from_assets: &["USDT", "USD"],
        to_assets: &["USDT", "EUR", "USD"],
        fee_percent: 0.15,
        eta_minutes: 5,
        compliance_score: 78,
    },
    RouteCandidate {
        route_id: "bridge-layerzero",
        label: "LayerZero USDT bridge",
        rails: &["crypto", "bridge", "layerzero"],
        from_assets: &["USDT", "USDC"],
        to_assets: &["USDT", "USDC", "EUR"],
        fee_percent: 0.22,
        eta_minutes: 12,
        compliance_score: 72,
    },
    RouteCandidate {
        route_id: "cex-liquidity",
        label: "CEX spot conversion",
        rails: &["crypto", "cex"],
        from_assets: &["USDT", "USDC", "BTC"],
        to_assets: &["EUR", "USD", "USDT"],
        fee_percent: 0.28,
        eta_minutes: 8,
        compliance_score: 80,
    },
    RouteCandidate {
        route_id: "cbdc-pilot",
        label: "CBDC pilot corridor",
        rails: &["cbdc", "bank"],
        from_assets: &["EUR", "CNY"],
        to_assets: &["EUR", "CNY"],
        fee_percent: 0.12,
        eta_minutes: 3,
        compliance_score: 99,
    },
];

pub fn quote(request: &QuoteRequest, spot_rate: f64) -> Vec<RouteQuote> {
    let from = request.from_asset.to_uppercase();
    let to = request.to_asset.to_uppercase();

    let mut routes: Vec<RouteQuote> = CATALOG
        .iter()
        .filter(|c| c.from_assets.contains(&from.as_str()) && c.to_assets.contains(&to.as_str()))
        .map(|c| {
            let fee_multiplier = 1.0 - (c.fee_percent / 100.0);
            let estimated_receive =
                ((request.amount * spot_rate * fee_multiplier) * 100.0).round() / 100.0;
            RouteQuote {
                route_id: c.route_id.to_string(),
                label: c.label.to_string(),
                rails: c.rails.iter().map(|r| (*r).to_string()).collect(),
                fee_percent: c.fee_percent,
                eta_minutes: c.eta_minutes,
                compliance_score: c.compliance_score,
                spot_rate,
                estimated_receive,
            }
        })
        .collect();

    sort_by_preference(&mut routes, request.preference);
    routes.truncate(3);
    routes
}

fn sort_by_preference(routes: &mut [RouteQuote], preference: RoutePreference) {
    routes.sort_by(|a, b| match preference {
        RoutePreference::Cheapest => a
            .fee_percent
            .partial_cmp(&b.fee_percent)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then_with(|| a.eta_minutes.cmp(&b.eta_minutes)),
        RoutePreference::Fastest => a
            .eta_minutes
            .cmp(&b.eta_minutes)
            .then_with(|| {
                a.fee_percent
                    .partial_cmp(&b.fee_percent)
                    .unwrap_or(std::cmp::Ordering::Equal)
            }),
        RoutePreference::Compliant => b
            .compliance_score
            .cmp(&a.compliance_score)
            .then_with(|| {
                a.fee_percent
                    .partial_cmp(&b.fee_percent)
                    .unwrap_or(std::cmp::Ordering::Equal)
            }),
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::QuoteRequest;

    #[test]
    fn returns_routes_for_usdt_to_eur() {
        let request = QuoteRequest {
            from_asset: "USDT".into(),
            to_asset: "EUR".into(),
            amount: 1000.0,
            preference: RoutePreference::Cheapest,
        };
        let routes = quote(&request, 0.92);
        assert!(!routes.is_empty());
        assert!(routes.len() <= 3);
    }

    #[test]
    fn cheapest_sorts_by_fee() {
        let request = QuoteRequest {
            from_asset: "USDT".into(),
            to_asset: "EUR".into(),
            amount: 500.0,
            preference: RoutePreference::Cheapest,
        };
        let routes = quote(&request, 0.92);
        for pair in routes.windows(2) {
            assert!(pair[0].fee_percent <= pair[1].fee_percent);
        }
    }

    #[test]
    fn unknown_pair_returns_empty() {
        let request = QuoteRequest {
            from_asset: "XYZ".into(),
            to_asset: "ABC".into(),
            amount: 100.0,
            preference: RoutePreference::Fastest,
        };
        assert!(quote(&request, 1.0).is_empty());
    }
}
