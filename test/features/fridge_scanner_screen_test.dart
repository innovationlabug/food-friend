import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/fridge_vision_service.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/presentation/fridge_scanner_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IngredientStorageService storageService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storageService = IngredientStorageService();
  });

  Widget createWidget({
    FridgeVisionService? visionService,
    Uint8List? initialImageBytes,
  }) {
    return MaterialApp(
      home: FridgeScannerScreen(
        storageService: storageService,
        visionService: visionService,
        initialImageBytes: initialImageBytes,
      ),
    );
  }

  group('US-3.2: FridgeScannerScreen UI & Confirmation Flow', () {
    testWidgets('renders initial prompt with camera and gallery actions in Spanish',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Escanear refrigerador'), findsOneWidget);
      expect(find.text('Detectar ingredientes por foto'), findsOneWidget);
      expect(find.text('Tomar foto con la cámara'), findsOneWidget);
      expect(find.text('Elegir foto de la galería / archivo'), findsOneWidget);
    });

    testWidgets('displays loading state with Spanish message while processing photo',
        (tester) async {
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({'success': true, 'items': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final visionService = FridgeVisionService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/detect-fridge',
      );

      await tester.pumpWidget(
        createWidget(
          visionService: visionService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );

      // Verify loading state appears
      expect(
        find.text('Analizando alimentos en tu refrigerador...'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('displays checklist with high confidence items pre-selected and confirms addition',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'summary': 'Alimentos encontrados en refrigerador',
            'items': [
              {
                'name': 'Ketchup Pollo Campero',
                'standardIngredient': 'Ketchup',
                'brand': 'Pollo Campero',
                'quantity': '1 botella',
                'confidence': 'high',
                'isLocalBrand': true,
                'category': 'Condimentos',
              },
              {
                'name': 'Frijoles volteados Ducal',
                'standardIngredient': 'Frijoles volteados',
                'brand': 'Ducal',
                'quantity': '1 bolsa',
                'confidence': 'high',
                'isLocalBrand': true,
                'category': 'Granos',
              },
              {
                'name': 'Salsa picante genérica',
                'standardIngredient': 'Salsa picante',
                'brand': 'Genérica',
                'quantity': '1 frasco',
                'confidence': 'low',
                'isLocalBrand': false,
                'category': 'Condimentos',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final visionService = FridgeVisionService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/detect-fridge',
      );

      await tester.pumpWidget(
        createWidget(
          visionService: visionService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pumpAndSettle();

      // Verify items are displayed
      expect(find.text('Ketchup'), findsOneWidget);
      expect(find.text('Frijoles volteados'), findsOneWidget);
      expect(find.text('Salsa picante'), findsOneWidget);

      // Checkboxes: 2 high confidence items should be pre-selected
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes.length, 3);
      expect(checkboxes[0].value, isTrue); // Ketchup (high)
      expect(checkboxes[1].value, isTrue); // Frijoles (high)
      expect(checkboxes[2].value, isFalse); // Salsa picante (low)

      // Verify bottom button has count 2
      expect(find.text('Agregar seleccionados (2)'), findsOneWidget);

      // Tap low confidence item to select it as well
      await tester.tap(find.text('Salsa picante'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar seleccionados (3)'), findsOneWidget);

      // Tap button to confirm additions
      await tester.tap(find.text('Agregar seleccionados (3)'));
      await tester.pumpAndSettle();

      // Verify items were persisted to storage
      final stored = await storageService.getIngredients();
      expect(stored.length, 3);
      expect(stored.map((i) => i.name), containsAll(['Ketchup', 'Frijoles volteados', 'Salsa picante']));
    });

    testWidgets('shows client-side fallback on error and allows navigating to manual entry',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'No se pudo conectar con el servidor',
          }),
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final visionService = FridgeVisionService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/detect-fridge',
      );

      await tester.pumpWidget(
        createWidget(
          visionService: visionService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pumpAndSettle();

      // Error message in Spanish
      expect(find.text('No se pudo completar el análisis'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Ingresar manualmente'), findsOneWidget);

      // Tap 'Ingresar manualmente'
      await tester.tap(find.text('Ingresar manualmente'));
      await tester.pumpAndSettle();
    });
  });
}
