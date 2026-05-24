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
        code: "JPY",
        name: "Japanese Yen",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "PLN",
        name: "Polish Zloty",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "TRY",
        name: "Turkish Lira",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "RUB",
        name: "Russian Ruble",
        kind: AssetKind::Fiat,
    },
    AssetInfo {
        code: "AED",
        name: "UAE Dirham",
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
    AssetInfo {
        code: "ETH",
        name: "Ethereum",
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

pub fn is_fiat(code: &str) -> bool {
    let code = code.trim().to_uppercase();
    SUPPORTED
        .iter()
        .any(|a| a.code == code && matches!(a.kind, AssetKind::Fiat))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lists_fourteen_assets() {
        assert_eq!(supported_assets().len(), 14);
    }

    #[test]
    fn recognizes_usdt_and_jpy() {
        assert!(is_supported("usdt"));
        assert!(is_supported("jpy"));
        assert!(is_fiat("EUR"));
        assert!(!is_fiat("USDT"));
        assert!(!is_supported("XYZ"));
    }
}
