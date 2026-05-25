import 'package:cybertranspay/models/route_quote.dart';
import 'package:cybertranspay/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchQuote parses response', () async {
    final client = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/health')) {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response(
          '''
{
  "routes": [{
    "route_id": "stablecoin-tron",
    "label": "USDT",
    "rails": ["crypto"],
    "fee_percent": 0.15,
    "eta_minutes": 5,
    "compliance_score": 78,
    "spot_rate": 0.92,
    "estimated_receive": 998.5
  }],
  "selected_preference": "cheapest",
  "spot_rate": 0.92,
  "rate_source": "mock",
  "live_pricing": false
}
''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final quote = await client.fetchQuote(
      const QuoteRequest(
        fromAsset: 'USDT',
        toAsset: 'EUR',
        amount: 1000,
        preference: 'cheapest',
      ),
    );

    expect(quote.routes, hasLength(1));
    expect(quote.routes.first.routeId, 'stablecoin-tron');
  });
}
