// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bitirme_proje/screens/splash/splash_screen.dart';

void main() {
  testWidgets('Splash ekranı render oluyor', (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp());
    await tester.pump(); // ilk frame

    expect(find.text('FitPhysio'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: SplashScreen(enableAutoNavigate: false),
    );
  }
}
