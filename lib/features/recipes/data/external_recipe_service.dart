import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/recipe.dart';
import '../domain/recipe_search_result.dart';
import 'recipe_search_service.dart';

/// Encapsulates the results of a recipe discovery inquiry,
/// identifying whether recipes originated from local search, external API, or offline fallback.
class RecipeDiscoveryResponse {
  const RecipeDiscoveryResponse({
    required this.results,
    this.source = 'local',
    this.fallbackMessage,
  });

  /// The ranked list of recipe search results.
  final List<RecipeSearchResult> results;

  /// Origin of the results: 'local', 'external', or 'fallback'.
  final String source;

  /// Explanatory message when fallback triggered due to network or empty external results.
  final String? fallbackMessage;

  bool get isFallback => source == 'fallback';
  bool get isExternal => source == 'external';
  bool get isLocal => source == 'local';
}

/// Service that coordinates traditional external recipe API lookups via backend proxy
/// (`/api/recipes`) and manages graceful fallbacks to the local recipe dataset.
class ExternalRecipeService {
  ExternalRecipeService({
    http.Client? client,
    String? proxyBaseUrl,
  })  : _client = client ?? http.Client(),
        _proxyBaseUrl = proxyBaseUrl ?? '/api/recipes';

  final http.Client _client;
  final String _proxyBaseUrl;

  /// Discovers recipes for the user's selected ingredients:
  /// 1. Queries local dataset first.
  /// 2. If 0 local matches, queries external recipe API proxy.
  /// 3. If external API returns 0 or fails/offline, falls back to closest partial local matches.
  Future<RecipeDiscoveryResponse> discoverRecipes({
    required List<String> selectedIngredients,
    required RecipeSearchService localSearchService,
  }) async {
    if (selectedIngredients.isEmpty) {
      return const RecipeDiscoveryResponse(
        results: [],
        source: 'local',
      );
    }

    // 1. Search local dataset first
    final localMatches = localSearchService.searchRecipes(
      selectedIngredientNames: selectedIngredients,
      minMatchCount: 1,
    );

    if (localMatches.isNotEmpty) {
      return RecipeDiscoveryResponse(
        results: localMatches,
        source: 'local',
      );
    }

    // 2. Zero local matches: automatically query external recipe API
    try {
      final externalRecipes = await fetchExternalRecipes(selectedIngredients);

      if (externalRecipes.isNotEmpty) {
        final externalResults = localSearchService.searchRecipes(
          selectedIngredientNames: selectedIngredients,
          recipePool: externalRecipes,
          minMatchCount: 0,
        );

        return RecipeDiscoveryResponse(
          results: externalResults,
          source: 'external',
        );
      }
    } catch (_) {
      // Offline, network timeout, or server error -> trigger local fallback below
    }

    // 3. Graceful fallback: closest partial matches from local dataset
    final partials = localSearchService.findClosestPartialMatches(
      selectedIngredients,
      limit: 5,
    );

    return RecipeDiscoveryResponse(
      results: partials,
      source: 'fallback',
      fallbackMessage:
          'No se encontraron recetas exactas en el recetario externo o te encuentras sin conexión. Te mostramos las alternativas locales más cercanas.',
    );
  }

  /// Calls the backend proxy endpoint `/api/recipes` to query traditional recipe databases.
  Future<List<Recipe>> fetchExternalRecipes(List<String> ingredients) async {
    if (ingredients.isEmpty) return const [];

    final candidateUris = _buildCandidateUris();
    http.Response? lastResponse;
    Object? lastError;

    for (final uri in candidateUris) {
      try {
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'ingredients': ingredients}),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final Map<String, dynamic> body =
              jsonDecode(response.body) as Map<String, dynamic>;
          final rawList = body['recipes'] as List<dynamic>?;

          if (rawList == null || rawList.isEmpty) {
            return const [];
          }

          return rawList
              .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        lastResponse = response;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastResponse != null) {
      throw http.ClientException(
        'Error al consultar el recetario externo (código: ${lastResponse.statusCode})',
        candidateUris.first,
      );
    }

    if (lastError != null) {
      throw lastError;
    }

    return const [];
  }

  /// Resolves candidate URLs for calling the backend proxy.
  /// Handles production Vercel paths, test URLs, and local dev dual-server routing (localhost:8080 -> localhost:3000).
  List<Uri> _buildCandidateUris() {
    final rawUri = Uri.parse(_proxyBaseUrl);

    // If explicit scheme is present (e.g. in tests: 'https://test/api/recipes'), use only that.
    if (rawUri.hasScheme) {
      return [rawUri];
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocalhost = host == 'localhost' || host == '127.0.0.1';
      if (isLocalhost && Uri.base.port != 3000) {
        // In local browser development, Flutter's shelf server on port 8080 does not host /api.
        // Try the local Node API server on port 3000 first, then fall back to the relative path.
        final localUri = Uri.parse('http://localhost:3000${_proxyBaseUrl.startsWith('/') ? '' : '/'}$_proxyBaseUrl');
        return [localUri, rawUri];
      }
      return [rawUri];
    }

    // Non-web (Dart VM, Android, etc.)
    return [
      Uri.parse('http://localhost:3000${_proxyBaseUrl.startsWith('/') ? '' : '/'}$_proxyBaseUrl'),
      Uri.parse('http://localhost:8080${_proxyBaseUrl.startsWith('/') ? '' : '/'}$_proxyBaseUrl'),
    ];
  }
}
