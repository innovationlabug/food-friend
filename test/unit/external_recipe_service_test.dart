import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/recipes/data/external_recipe_service.dart';
import 'package:food_friend/features/recipes/data/recipe_search_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('US-4.3: ExternalRecipeService Integration & Fallback', () {
    late RecipeSearchService localSearchService;

    setUp(() {
      localSearchService = RecipeSearchService();
    });

    test('discoverRecipes prioritizes local dataset when local matches exist', () async {
      var externalApiCalled = false;
      final mockClient = MockClient((request) async {
        externalApiCalled = true;
        return http.Response('{"success": true, "recipes": []}', 200);
      });

      final service = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://foodfriend.test/api/recipes',
      );

      // Ingredients matching local "Pepián" or "Caldo de pollo"
      final response = await service.discoverRecipes(
        selectedIngredients: ['Pechuga de pollo', 'Güisquil'],
        localSearchService: localSearchService,
      );

      expect(response.isLocal, isTrue);
      expect(response.source, equals('local'));
      expect(response.results, isNotEmpty);
      expect(externalApiCalled, isFalse, reason: 'Must not call external API when local matches exist');
    });

    test('discoverRecipes queries external API when zero local matches exist and maps response', () async {
      var externalApiCalled = false;
      final mockClient = MockClient((request) async {
        externalApiCalled = true;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['ingredients'], contains('curry'));

        const mockResponse = {
          'success': true,
          'count': 1,
          'recipes': [
            {
              'id': 'external_52772',
              'title': 'Pollo Teriyaki al Horno',
              'description': 'Receta tradicional adaptada (Japón)',
              'category': 'Pollo',
              'source': 'external',
              'prepTimeMinutes': 15,
              'cookTimeMinutes': 25,
              'servings': 4,
              'ingredients': [
                {'name': 'Pollo', 'displayAmount': '500g'},
                {'name': 'Salsa de soya', 'displayAmount': '2 cucharadas'},
              ],
              'instructions': [
                'Marinar el pollo con la salsa.',
                'Hornear a 200 grados por 25 minutos.',
              ],
            }
          ]
        };

        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://foodfriend.test/api/recipes',
      );

      // Unmatched ingredient locally
      final response = await service.discoverRecipes(
        selectedIngredients: ['curry'],
        localSearchService: localSearchService,
      );

      expect(externalApiCalled, isTrue);
      expect(response.isExternal, isTrue);
      expect(response.source, equals('external'));
      expect(response.results.length, equals(1));
      expect(response.results.first.recipe.title, equals('Pollo Teriyaki al Horno'));
      expect(response.results.first.recipe.source, equals('external'));
    });

    test('discoverRecipes falls back to closest local partial matches when offline or network fails', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network unreachable (offline test)', request.url);
      });

      final service = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://foodfriend.test/api/recipes',
      );

      final response = await service.discoverRecipes(
        selectedIngredients: ['IngredienteInexistenteXYZ'],
        localSearchService: localSearchService,
      );

      expect(response.isFallback, isTrue);
      expect(response.source, equals('fallback'));
      expect(response.fallbackMessage, isNotNull);
      expect(response.fallbackMessage, contains('recetario externo'));
      expect(response.results, isNotEmpty, reason: 'Must return closest partial local matches');
    });

    test('discoverRecipes falls back to local partial matches when external API returns zero results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'count': 0, 'recipes': []}),
          200,
        );
      });

      final service = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://foodfriend.test/api/recipes',
      );

      final response = await service.discoverRecipes(
        selectedIngredients: ['IngredienteInexistente12345'],
        localSearchService: localSearchService,
      );

      expect(response.isFallback, isTrue);
      expect(response.results, isNotEmpty);
      expect(response.fallbackMessage, isNotNull);
    });

    test('fetchExternalRecipes handles non-200 responses with an exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://foodfriend.test/api/recipes',
      );

      expect(
        () => service.fetchExternalRecipes(['tomate']),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('fetchExternalRecipes returns empty list for empty ingredient inputs', () async {
      final service = ExternalRecipeService();
      final result = await service.fetchExternalRecipes([]);
      expect(result, isEmpty);
    });
  });
}
