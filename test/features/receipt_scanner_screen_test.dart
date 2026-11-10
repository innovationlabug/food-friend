import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/data/receipt_parser_service.dart';
import 'package:food_friend/features/ingredients/presentation/receipt_scanner_screen.dart';
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
    ReceiptParserService? parserService,
    Uint8List? initialImageBytes,
  }) {
    return MaterialApp(
      home: ReceiptScannerScreen(
        storageService: storageService,
        parserService: parserService,
        initialImageBytes: initialImageBytes,
      ),
    );
  }

  group('US-3.4: ReceiptScannerScreen UI & Confirmation Flow', () {
    testWidgets('renders initial prompt with camera and gallery actions in Spanish',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Escanear recibo'), findsOneWidget);
      expect(find.text('Extraer alimentos de factura / ticket'), findsOneWidget);
      expect(find.text('Tomar foto del recibo'), findsOneWidget);
      expect(find.text('Elegir foto del recibo de la galería'), findsOneWidget);
    });

    testWidgets('displays loading state with Spanish message while processing receipt',
        (tester) async {
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({'success': true, 'items': []}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final parserService = ReceiptParserService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      await tester.pumpWidget(
        createWidget(
          parserService: parserService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );

      expect(
        find.text('Digitalizando recibo de supermercado...'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets(
        'displays checklist with high confidence items pre-selected, supermarket info in GTQ, and confirms addition',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'supermarket': 'Despensa Familiar Villa Nueva',
            'totalFacturaGtq': 155.60,
            'totalAlimentosGtq': 120.40,
            'summary': 'Ticket con 3 alimentos',
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
                'unitCount': 1,
                'priceGtq': 9.95,
                'totalPriceGtq': 9.95,
                'confidence': 'high',
              },
              {
                'rawName': 'ITEM NO VERIFICADO',
                'standardIngredient': 'Snack dulce',
                'brand': 'Genérica',
                'category': 'Snacks',
                'quantity': '1 unidad',
                'unitCount': 1,
                'priceGtq': 4.50,
                'totalPriceGtq': 4.50,
                'confidence': 'low',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final parserService = ReceiptParserService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      await tester.pumpWidget(
        createWidget(
          parserService: parserService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pumpAndSettle();

      // Supermarket info & prices in GTQ
      expect(find.text('Despensa Familiar Villa Nueva'), findsOneWidget);
      expect(find.textContaining('Alimentos: Q 120.40'), findsOneWidget);
      expect(find.textContaining('Total factura: Q 155.60'), findsOneWidget);
      // Verify unstructured summary paragraph is NOT rendered
      expect(find.text('Ticket con 3 alimentos'), findsNothing);

      // Items list
      expect(find.text('Arroz blanco'), findsOneWidget);
      expect(find.text('Frijol negro'), findsOneWidget);
      expect(find.text('Snack dulce'), findsOneWidget);

      // Checkbox state: 2 high confidence items pre-selected, 1 low unselected
      final checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes.length, 3);
      expect(checkboxes[0].value, isTrue); // Arroz blanco (high)
      expect(checkboxes[1].value, isTrue); // Frijol negro (high)
      expect(checkboxes[2].value, isFalse); // Snack dulce (low)

      // Confirm button label has count 2
      expect(find.text('Agregar seleccionados (2)'), findsOneWidget);

      // Toggle low confidence item
      await tester.tap(find.text('Snack dulce'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar seleccionados (3)'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Agregar seleccionados (3)'));
      await tester.pumpAndSettle();

      // Verify persisted in storage
      final stored = await storageService.getIngredients();
      expect(stored.length, 3);
      expect(stored.map((i) => i.name),
          containsAll(['Arroz blanco', 'Frijol negro', 'Snack dulce']));
    });

    testWidgets('shows client-side fallback on error and allows navigating to manual entry',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'No se pudo leer el recibo',
          }),
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final parserService = ReceiptParserService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      await tester.pumpWidget(
        createWidget(
          parserService: parserService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pumpAndSettle();

      // Error banner in Spanish
      expect(find.text('No se pudo procesar el recibo'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Ingresar manualmente'), findsOneWidget);

      // Tap 'Ingresar manualmente'
      await tester.tap(find.text('Ingresar manualmente'));
      await tester.pumpAndSettle();
    });

    testWidgets('sorts receipt items by confidence putting high-confidence items first',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'supermarket': 'La Torre Pradera',
            'summary': 'Resumen no estructurado',
            'items': [
              {
                'rawName': 'ITEM MEDIA CONF',
                'standardIngredient': 'Leche entera',
                'confidence': 'medium',
              },
              {
                'rawName': 'ITEM ALTA CONF',
                'standardIngredient': 'Huevos de gallina',
                'confidence': 'high',
              },
              {
                'rawName': 'ITEM BAJA CONF',
                'standardIngredient': 'Galleta dulce',
                'confidence': 'low',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final parserService = ReceiptParserService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      await tester.pumpWidget(
        createWidget(
          parserService: parserService,
          initialImageBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pumpAndSettle();

      // Summary is not rendered
      expect(find.text('Resumen no estructurado'), findsNothing);

      // Order check: Huevos (high) first, Leche (medium) second, Galleta (low) third
      final titles = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      final huevosIndex = titles.indexOf('Huevos de gallina');
      final lecheIndex = titles.indexOf('Leche entera');
      final galletaIndex = titles.indexOf('Galleta dulce');

      expect(huevosIndex, isNonNegative);
      expect(lecheIndex, isNonNegative);
      expect(galletaIndex, isNonNegative);
      expect(huevosIndex, lessThan(lecheIndex));
      expect(lecheIndex, lessThan(galletaIndex));
    });
  });
}

