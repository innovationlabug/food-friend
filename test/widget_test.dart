import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:food_friend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Shows first-launch mode selection then renders Spanish Home shell',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    SettingsController.instance.resetToDefaults();

    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // First-launch mode selection is shown
    expect(find.text('Elige cómo quieres usar la aplicación'), findsOneWidget);
    expect(find.text('Simple'), findsOneWidget);
    expect(find.text('Completa'), findsOneWidget);
    expect(find.text('Personalizada'), findsOneWidget);

    await tester.tap(find.text('Completa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Verify key titles and Spanish copy are rendered on HomeScreen
    expect(find.text('Food Friend'), findsOneWidget);
    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
    expect(find.text('Ingredientes disponibles'), findsOneWidget);
    expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
    expect(find.text('Asistente de nutrición'), findsNothing);
  });
}
