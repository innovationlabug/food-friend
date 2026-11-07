import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/main.dart';

void main() {
  testWidgets('Renders initial Spanish shell and navigation cards smoke test',
      (WidgetTester tester) async {
    // Build FoodFriendApp and settle animations/assets
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // Verify key titles and Spanish copy are rendered
    expect(find.text('Food Friend'), findsOneWidget);
    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
    expect(find.text('Asistente de nutrición'), findsOneWidget);
  });
}
