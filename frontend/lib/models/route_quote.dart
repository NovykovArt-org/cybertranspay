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
    required this.estimatedReceive,
  });

  factory RouteQuote.fromJson(Map<String, dynamic> json) => RouteQuote(
        routeId: json['route_id'] as String,
        label: json['label'] as String,
        rails: (json['rails'] as List<dynamic>).cast<String>(),
        feePercent: (json['fee_percent'] as num).toDouble(),
        etaMinutes: json['eta_minutes'] as int,
        complianceScore: json['compliance_score'] as int,
        estimatedReceive: (json['estimated_receive'] as num).toDouble(),
      );

  final String routeId;
  final String label;
  final List<String> rails;
  final double feePercent;
  final int etaMinutes;
  final int complianceScore;
  final double estimatedReceive;
}

class QuoteResponse {
  QuoteResponse({required this.routes, required this.preference});

  factory QuoteResponse.fromJson(Map<String, dynamic> json) => QuoteResponse(
        routes: (json['routes'] as List<dynamic>)
            .map((e) => RouteQuote.fromJson(e as Map<String, dynamic>))
            .toList(),
        preference: json['selected_preference'] as String? ?? 'cheapest',
      );

  final List<RouteQuote> routes;
  final String preference;
}
