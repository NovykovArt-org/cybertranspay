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
  "quote_id": "quote-1",
  "expires_at": "2026-05-26T08:30:00Z",
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
    expect(quote.quoteId, 'quote-1');
    expect(quote.routes.first.routeId, 'stablecoin-tron');
  });

  test('createTransfer parses response', () async {
    final client = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((request) async {
        expect(request.url.path, '/v1/transfers');
        return http.Response(
          '''
{
  "transfer_id": "transfer-1",
  "quote_id": "quote-1",
  "route_id": "stablecoin-tron",
  "from_asset": "USDT",
  "to_asset": "EUR",
  "amount": 1000,
  "estimated_receive": 918.62,
  "status": "completed",
  "created_at": "2026-05-26T08:31:00Z"
}
''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final transfer = await client.createTransfer(
      const CreateTransferRequest(
        quoteId: 'quote-1',
        routeId: 'stablecoin-tron',
      ),
    );

    expect(transfer.transferId, 'transfer-1');
    expect(transfer.status, 'completed');
    expect(transfer.estimatedReceive, 918.62);
  });
}
