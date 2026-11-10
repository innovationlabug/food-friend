import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/fridge_vision_service.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/data/receipt_parser_service.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
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

  group('E2E Flow Phase 3: Multi-Ingredient Photo Input (Fridge & Receipt Scanning)', () {
    testWidgets(
        'E2E Full Flow: Clean state -> Add Ingredient -> Scan Fridge Photo (sample03) -> Confirm -> Items appear in list',
        (tester) async {
      // Mock Vision Client simulating /api/detect-fridge for demo sample03_refrigerator.jpeg
      final mockFridgeClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'summary': 'Refrigerador con productos básicos de despensa guatemalteca',
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
                'name': 'Mayonesa Hellmann\'s',
                'standardIngredient': 'Mayonesa',
                'brand': 'Hellmann\'s',
                'quantity': '1 frasco',
                'confidence': 'high',
                'isLocalBrand': false,
                'category': 'Condimentos',
              },
              {
                'name': 'Queso amarillo en bloque',
                'standardIngredient': 'Queso cheddar',
                'brand': 'Genérica',
                'quantity': '1 trozo',
                'confidence': 'medium',
                'isLocalBrand': false,
                'category': 'Lácteos',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final fridgeVisionService = FridgeVisionService(
        client: mockFridgeClient,
        proxyBaseUrl: 'https://test/api/detect-fridge',
      );

      // 1. Launch AddIngredientScreen with injected fridgeVisionService
      await tester.pumpWidget(
        MaterialApp(
          home: AddIngredientScreen(
            storageService: storageService,
            visionService: fridgeVisionService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agregar ingrediente'), findsOneWidget);
      expect(find.text('Escanear con foto'), findsOneWidget);

      // 2. Tap 'Refrigerador' button in photo scanning card
      final fridgeBtn = find.widgetWithText(OutlinedButton, 'Refrigerador');
      expect(fridgeBtn, findsOneWidget);
      await tester.tap(fridgeBtn);
      await tester.pumpAndSettle();

      // Verify we navigated to FridgeScannerScreen
      expect(find.text('Escanear refrigerador'), findsOneWidget);
      expect(find.text('Detectar ingredientes por foto'), findsOneWidget);

      // 3. Tap demo sample photo 'Refrigerador completo'
      final sampleTile = find.text('Refrigerador completo');
      expect(sampleTile, findsOneWidget);
      await tester.tap(sampleTile);
      await tester.pumpAndSettle();

      // 4. Verify detected items are displayed
      expect(find.text('Ketchup'), findsOneWidget);
      expect(find.text('Frijoles volteados'), findsOneWidget);
      expect(find.text('Mayonesa'), findsOneWidget);
      expect(find.text('Queso cheddar'), findsOneWidget);

      // Checkboxes: 3 high confidence items pre-selected, 1 medium unselected
      expect(find.text('Agregar seleccionados (3)'), findsOneWidget);

      // 5. Confirm addition
      await tester.tap(find.text('Agregar seleccionados (3)'));
      await tester.pumpAndSettle();

      // 6. Verify items are persisted in storage
      final stored = await storageService.getIngredients();
      expect(stored.length, 3);
      expect(
        stored.map((i) => i.name),
        containsAll(['Ketchup', 'Frijoles volteados', 'Mayonesa']),
      );

      // 7. Verify items appear in Shopping List view
      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScreen(storageService: storageService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ketchup'), findsOneWidget);
      expect(find.text('Frijoles volteados'), findsOneWidget);
      expect(find.text('Mayonesa'), findsOneWidget);
    });

    testWidgets(
        'E2E Full Flow: Add Ingredient -> Scan Supermarket Receipt (sample02) -> Confirm -> Items appear in list',
        (tester) async {
      // Mock Client simulating /api/parse-receipt for demo sample02.jpg
      final mockReceiptClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'supermarket': 'Despensa Familiar Villa Nueva',
            'totalFacturaGtq': 155.60,
            'totalAlimentosGtq': 120.40,
            'summary': 'Ticket con alimentos de despensa guatemalteca',
            'items': [
              {
                'rawName': 'MOLINERO AR/BLA 400G',
                'standardIngredient': 'Arroz blanco',
                'brand': 'Molinero',
                'category': 'Granos',
                'quantity': '400 g',
                'unitCount': 2,
                'priceGtq': 5.95,
                'totalPriceGtq': 11.90,
                'confidence': 'high',
              },
              {
                'rawName': 'LA COSE. FJOL/NG 400',
                'standardIngredient': 'Frijol negro',
                'brand': 'La Cosecha',
                'category': 'Granos',
                'quantity': '400 g',
                'unitCount': 2,
                'priceGtq': 9.95,
                'totalPriceGtq': 19.90,
                'confidence': 'high',
              },
              {
                'rawName': 'IDEAL ACTE/VEG 750ML',
                'standardIngredient': 'Aceite vegetal',
                'brand': 'Ideal',
                'category': 'Grasas y aceites',
                'quantity': '750 ml',
                'unitCount': 1,
                'priceGtq': 16.90,
                'totalPriceGtq': 16.90,
                'confidence': 'high',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final receiptParserService = ReceiptParserService(
        client: mockReceiptClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      // 1. Launch AddIngredientScreen with injected receiptParserService
      await tester.pumpWidget(
        MaterialApp(
          home: AddIngredientScreen(
            storageService: storageService,
            parserService: receiptParserService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Tap 'Recibo' button
      final receiptBtn = find.widgetWithText(OutlinedButton, 'Recibo');
      expect(receiptBtn, findsOneWidget);
      await tester.tap(receiptBtn);
      await tester.pumpAndSettle();

      // Verify we navigated to ReceiptScannerScreen
      expect(find.text('Escanear recibo'), findsOneWidget);

      // 3. Tap demo sample photo 'Recibo Despensa / Multiproducto'
      final sampleTile = find.text('Recibo Despensa / Multiproducto');
      expect(sampleTile, findsOneWidget);
      await tester.tap(sampleTile);
      await tester.pumpAndSettle();

      // 4. Verify supermarket info and prices in Quetzales
      expect(find.text('Despensa Familiar Villa Nueva'), findsOneWidget);
      expect(find.textContaining('Q 120.40'), findsOneWidget);

      // 5. Verify ingredients extracted
      expect(find.text('Arroz blanco'), findsOneWidget);
      expect(find.text('Frijol negro'), findsOneWidget);
      expect(find.text('Aceite vegetal'), findsOneWidget);

      expect(find.text('Agregar seleccionados (3)'), findsOneWidget);

      // 6. Confirm addition
      await tester.tap(find.text('Agregar seleccionados (3)'));
      await tester.pumpAndSettle();

      // 7. Verify items are persisted in storage
      final stored = await storageService.getIngredients();
      expect(stored.length, 3);
      expect(
        stored.map((i) => i.name),
        containsAll(['Arroz blanco', 'Frijol negro', 'Aceite vegetal']),
      );

      // 8. Return to Shopping List and verify rendered cleanly with zero overflows
      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScreen(storageService: storageService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco'), findsOneWidget);
      expect(find.text('Frijol negro'), findsOneWidget);
      expect(find.text('Aceite vegetal'), findsOneWidget);
    });
  });
}
