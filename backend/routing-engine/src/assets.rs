use serde::Serialize;

#[derive(Debug, Clone, Copy, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum AssetKind {
    Fiat,
    Stablecoin,
    Crypto,
}

#[derive(Debug, Clone, Copy, Serialize)]
pub struct AssetInfo {
    pub code: &'static str,
    pub name: &'static str,
    pub kind: AssetKind,
}

const SUPPORTED: &[AssetInfo] = &[
    AssetInfo {
        code: "USD",
        name: "US Dollar",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "EUR",
        name: "Euro",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "GBP",
        name: "British Pound",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "CHF",
        name: "Swiss Franc",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "CNY",
        name: "Chinese Yuan",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "USDT",
        name: "Tether USD",
        kind: AssetKind::Stablecoin,
    },
    AssetInfo {
        code: "USDC",
        name: "USD Coin",
        kind: AssetKind::Stablecoin,
    },
    AssetInfo {
        code: "BTC",
        name: "Bitcoin",
        kind: AssetKind::Crypto,
    },
];

pub fn supported_assets() -> &'static [AssetInfo] {
    SUPPORTED
}

pub fn is_supported(code: &str) -> bool {
    let code = code.trim().to_uppercase();
    SUPPORTED.iter().any(|a| a.code == code)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lists_eight_assets() {
        assert_eq!(supported_assets().len(), 8);
    }

    #[test]
    fn recognizes_usdt() {
        assert!(is_supported("usdt"));
        assert!(!is_supported("XYZ"));
    }
}
