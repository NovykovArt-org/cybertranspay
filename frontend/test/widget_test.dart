import 'package:cybertranspay/main.dart';
import 'package:cybertranspay/models/route_quote.dart';
import 'package:cybertranspay/services/api_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'http://test');

  QuoteRequest? lastQuoteRequest;

  @override
  Future<bool> checkHealth() async => true;

  @override
  Future<QuoteResponse> fetchQuote(QuoteRequest request) async {
    lastQuoteRequest = request;
    return QuoteResponse(
      quoteId: 'quote-1',
      expiresAt: DateTime.utc(2026, 5, 26, 8, 30),
      preference: request.preference,
      spotRate: 0.92,
      rateSource: 'mock',
      livePricing: false,
      routes: [
        RouteQuote(
          routeId: 'bank-sepa',
          label: 'SEPA bank rail',
          rails: const ['fiat', 'bank'],
          feePercent: 0.35,
          etaMinutes: 1440,
          complianceScore: 95,
          spotRate: 0.92,
          estimatedReceive: 916.78,
        ),
      ],
    );
  }

  @override
  Future<TransferResponse> createTransfer(
          CreateTransferRequest request) async =>
      TransferResponse(
        transferId: 'transfer-1',
        quoteId: request.quoteId,
        routeId: request.routeId,
        fromAsset: 'USDT',
        toAsset: 'EUR',
        amount: 1000,
        estimatedReceive: 918.62,
        status: 'completed',
        createdAt: DateTime.utc(2026, 5, 26, 8, 31),
      );

  @override
  Future<TransferResponse> getTransfer(String transferId) async =>
      TransferResponse(
        transferId: transferId,
        quoteId: 'quote-1',
        routeId: 'stablecoin-tron',
        fromAsset: 'USDT',
        toAsset: 'EUR',
        amount: 1000,
        estimatedReceive: 918.62,
        status: 'completed',
        createdAt: DateTime.utc(2026, 5, 26, 8, 31),
      );
}

void main() {
  testWidgets('shows app title', (tester) async {
    await tester.pumpWidget(CyberTransPayApp(api: ApiClient()));
    expect(find.text('CyberTransPay'), findsOneWidget);
  });

  testWidgets('creates transfer from selected route', (tester) async {
    final api = FakeApiClient();
    await tester.pumpWidget(CyberTransPayApp(api: api));

    await tester.tap(find.text('Маршруты'));
    await tester.pumpAndSettle();

    expect(find.text('Выберите страну'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('from-country-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('США').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('to-country-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Еврозона').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Подобрать маршрут'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подобрать маршрут'));
    await tester.pumpAndSettle();

    expect(api.lastQuoteRequest?.fromAsset, 'USD');
    expect(api.lastQuoteRequest?.toAsset, 'EUR');
    expect(find.textContaining('Quote: quote-1'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('SEPA bank rail'), findsOneWidget);
    await tester.tap(find.text('Выбрать маршрут'));
    await tester.pumpAndSettle();

    expect(find.text('Подтверждение перевода'), findsOneWidget);
    expect(find.text('К получению'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('recipient-field')),
      'Alex Receiver',
    );
    await tester.ensureVisible(find.text('Подтвердить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();

    expect(find.text('Перевод создан'), findsOneWidget);
    expect(find.text('ID: transfer-1'), findsOneWidget);
    expect(find.text('Статус: completed'), findsOneWidget);
    expect(find.text('Получатель: Alex Receiver'), findsOneWidget);

    await tester.tap(find.text('Обновить статус'));
    await tester.pumpAndSettle();

    expect(find.text('Статус обновлён'), findsOneWidget);
    expect(find.text('Статус: completed'), findsOneWidget);
  });
}
