import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:careconnect_flutter/main.dart';

void main() {
  testWidgets('CareConnect smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CareConnectApp(),
      ),
    );
    expect(find.byType(CareConnectApp), findsOneWidget);
  });
}
