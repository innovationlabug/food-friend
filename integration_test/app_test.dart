import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_friend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E integration test: launches app shell and verifies Spanish navigation',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify root shell headers and cards render in Spanish
    expect(find.text('Food Friend'), findsOneWidget);
    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
    expect(find.text('Asistente de nutrición'), findsOneWidget);
  });
}

