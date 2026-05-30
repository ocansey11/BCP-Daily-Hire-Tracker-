import 'package:flutter_test/flutter_test.dart';
import 'package:bcp_daily_hire_tracker/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const BCPTrackerApp());
    expect(find.byType(BCPTrackerApp), findsOneWidget);
  });
}
