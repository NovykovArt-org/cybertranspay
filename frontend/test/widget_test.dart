import 'package:cybertranspay/main.dart';
import 'package:cybertranspay/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows app title', (tester) async {
    await tester.pumpWidget(CyberTransPayApp(api: ApiClient()));
    expect(find.text('CyberTransPay'), findsOneWidget);
  });
}
