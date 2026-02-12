// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:carvia/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:carvia/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const CarviaApp(),
      ),
    );

    // Verify that Splash screen is shown (Brand Name)
    expect(find.text('Carvia'), findsOneWidget);

    // Wait for Splash to finish (4 seconds)
    await tester.pump(const Duration(seconds: 4));
    // Pump transition (800ms)
    await tester.pump(const Duration(milliseconds: 800));
    // Pump once more to ensure layout
    await tester.pump();

    // Verify we are on Landing Page (Button)
    expect(find.text('Explore Marketplace'), findsOneWidget);
  });
}
