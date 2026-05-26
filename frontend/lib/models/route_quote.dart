class QuoteRequest {
  const QuoteRequest({
    required this.fromAsset,
    required this.toAsset,
    required this.amount,
    required this.preference,
  });

  final String fromAsset;
  final String toAsset;
  final double amount;
  final String preference;

  Map<String, dynamic> toJson() => {
        'from_asset': fromAsset,
        'to_asset': toAsset,
        'amount': amount,
        'preference': preference,
      };
}

class RouteQuote {
  RouteQuote({
    required this.routeId,
    required this.label,
    required this.rails,
    required this.feePercent,
    required this.etaMinutes,
    required this.complianceScore,
    required this.spotRate,
    required this.estimatedReceive,
  });

  factory RouteQuote.fromJson(Map<String, dynamic> json) => RouteQuote(
        routeId: json['route_id'] as String,
        label: json['label'] as String,
        rails: (json['rails'] as List<dynamic>).cast<String>(),
        feePercent: (json['fee_percent'] as num).toDouble(),
        etaMinutes: json['eta_minutes'] as int,
        complianceScore: json['compliance_score'] as int,
        spotRate: (json['spot_rate'] as num).toDouble(),
        estimatedReceive: (json['estimated_receive'] as num).toDouble(),
      );

  final String routeId;
  final String label;
  final List<String> rails;
  final double feePercent;
  final int etaMinutes;
  final int complianceScore;
  final double spotRate;
  final double estimatedReceive;
}

class QuoteResponse {
  QuoteResponse({
    required this.quoteId,
    required this.expiresAt,
    required this.routes,
    required this.preference,
    required this.spotRate,
    required this.rateSource,
    required this.livePricing,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) => QuoteResponse(
        quoteId: json['quote_id'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        routes: (json['routes'] as List<dynamic>)
            .map((e) => RouteQuote.fromJson(e as Map<String, dynamic>))
            .toList(),
        preference: json['selected_preference'] as String? ?? 'cheapest',
        spotRate: (json['spot_rate'] as num).toDouble(),
        rateSource: json['rate_source'] as String? ?? 'unknown',
        livePricing: json['live_pricing'] as bool? ?? false,
      );

  final String quoteId;
  final DateTime expiresAt;
  final List<RouteQuote> routes;
  final String preference;
  final double spotRate;
  final String rateSource;
  final bool livePricing;
}

class CreateTransferRequest {
  const CreateTransferRequest({
    required this.quoteId,
    required this.routeId,
  });

  final String quoteId;
  final String routeId;

  Map<String, dynamic> toJson() => {
        'quote_id': quoteId,
        'route_id': routeId,
      };
}

class TransferResponse {
  TransferResponse({
    required this.transferId,
    required this.quoteId,
    required this.routeId,
    required this.fromAsset,
    required this.toAsset,
    required this.amount,
    required this.estimatedReceive,
    required this.status,
    required this.createdAt,
  });

  factory TransferResponse.fromJson(Map<String, dynamic> json) =>
      TransferResponse(
        transferId: json['transfer_id'] as String,
        quoteId: json['quote_id'] as String,
        routeId: json['route_id'] as String,
        fromAsset: json['from_asset'] as String,
        toAsset: json['to_asset'] as String,
        amount: (json['amount'] as num).toDouble(),
        estimatedReceive: (json['estimated_receive'] as num).toDouble(),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String transferId;
  final String quoteId;
  final String routeId;
  final String fromAsset;
  final String toAsset;
  final double amount;
  final double estimatedReceive;
  final String status;
  final DateTime createdAt;
}
