import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:thekoordinasi/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TheKoordinasiApp()));

    // Verify splash screen renders
    expect(find.text('KOORDINASI'), findsOneWidget);
  });
}
