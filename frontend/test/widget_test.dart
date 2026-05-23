import 'package:cybertranspay/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows app title', (tester) async {
    await tester.pumpWidget(const CyberTransPayApp());
    expect(find.text('CyberTransPay'), findsOneWidget);
  });
}
