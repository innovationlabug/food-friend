import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/supermarket.dart';
import '../domain/supermarket_deal.dart';
import 'fallback_sales_data.dart';

/// Result returned by [SalesService.fetchDeals].
class SalesFetchResult {
  const SalesFetchResult({
    required this.deals,
    required this.fetchedAt,
    required this.isFallback,
  });

  final List<SupermarketDeal> deals;
  final DateTime fetchedAt;
  final bool isFallback;
}

/// Fetches cached supermarket sales from `/api/sales` with local caching
/// in [SharedPreferences] and an offline curated GTQ fallback snapshot.
class SalesService {
  SalesService({
    http.Client? client,
    SharedPreferences? preferences,
    this.proxyBaseUrl = '/api/sales',
    this.cacheTtl = const Duration(hours: 4),
  })  : _client = client ?? http.Client(),
        _prefsOverride = preferences;

  final http.Client _client;
  final SharedPreferences? _prefsOverride;
  SharedPreferences? _cachedPrefs;
  final String proxyBaseUrl;
  final Duration cacheTtl;

  static const String cacheStorageKey = 'food_friend_sales_snapshot';
  static const String favoriteSupermarketKey = 'food_friend_favorite_supermarket';

  Future<SharedPreferences> get _prefs async {
    return _prefsOverride ?? (_cachedPrefs ??= await SharedPreferences.getInstance());
  }

  /// Returns supermarket deals, preferring fresh local cache, then `/api/sales`,
  /// and falling back gracefully to [FallbackSalesData.deals] when offline.
  Future<SalesFetchResult> fetchDeals({bool forceRefresh = false}) async {
    final cached = await _readCachedSnapshot();
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < cacheTtl) {
      return cached;
    }

    final candidateUris = _buildCandidateUris();
    for (final uri in candidateUris) {
      try {
        final response = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final rawDeals = decoded['deals'] as List<dynamic>? ?? const [];
            final parsedDeals = rawDeals
                .whereType<Map<String, dynamic>>()
                .map(SupermarketDeal.fromJson)
                .where((d) => d.productName.isNotEmpty && d.salePriceGtq > 0)
                .toList();

            if (parsedDeals.isNotEmpty) {
              final fetchedAt = DateTime.tryParse(
                    decoded['fetchedAt']?.toString() ?? '',
                  ) ??
                  DateTime.now();
              final result = SalesFetchResult(
                deals: parsedDeals,
                fetchedAt: fetchedAt,
                isFallback: decoded['sourceMode'] == 'fallback',
              );
              await _saveCachedSnapshot(result);
              return result;
            }
          }
        }
      } catch (_) {
        // Try next candidate URI or fall back below
      }
    }

    if (cached != null) {
      return cached;
    }

    return SalesFetchResult(
      deals: FallbackSalesData.deals,
      fetchedAt: DateTime.now(),
      isFallback: true,
    );
  }

  /// Returns locally cached supermarket deals or [FallbackSalesData.deals]
  /// without performing network requests (safe for non-blocking UI rendering).
  Future<List<SupermarketDeal>> getCachedOrFallbackDeals() async {
    final cached = await _readCachedSnapshot();
    if (cached != null && cached.deals.isNotEmpty) {
      return cached.deals;
    }
    return FallbackSalesData.deals;
  }

  /// Retrieves the user's preferred supermarket ID if set.
  Future<String?> getFavoriteSupermarketId() async {
    final prefs = await _prefs;
    final id = prefs.getString(favoriteSupermarketKey);
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  /// Persists or clears the user's preferred supermarket ID.
  Future<void> setFavoriteSupermarketId(String? supermarketId) async {
    final prefs = await _prefs;
    if (supermarketId == null || supermarketId.trim().isEmpty) {
      await prefs.remove(favoriteSupermarketKey);
    } else {
      await prefs.setString(favoriteSupermarketKey, supermarketId.trim());
    }
  }

  /// Returns known Guatemalan supermarkets annotated with [Supermarket.isFavorite].
  Future<List<Supermarket>> getSupermarkets() async {
    final favoriteId = await getFavoriteSupermarketId();
    return Supermarket.knownSupermarkets
        .map((s) => s.copyWith(isFavorite: s.id == favoriteId))
        .toList();
  }

  Future<SalesFetchResult?> _readCachedSnapshot() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(cacheStorageKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final rawDeals = decoded['deals'] as List<dynamic>? ?? const [];
      final deals = rawDeals
          .whereType<Map<String, dynamic>>()
          .map(SupermarketDeal.fromJson)
          .where((d) => d.productName.isNotEmpty && d.salePriceGtq > 0)
          .toList();
      if (deals.isEmpty) return null;

      final fetchedAt = DateTime.tryParse(
            decoded['fetchedAt']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return SalesFetchResult(
        deals: deals,
        fetchedAt: fetchedAt,
        isFallback: decoded['isFallback'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedSnapshot(SalesFetchResult result) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
        cacheStorageKey,
        jsonEncode({
          'fetchedAt': result.fetchedAt.toIso8601String(),
          'isFallback': result.isFallback,
          'deals': result.deals.map((d) => d.toJson()).toList(),
        }),
      );
    } catch (_) {
      // Ignore cache write errors
    }
  }

  List<Uri> _buildCandidateUris() {
    final rawUri = Uri.parse(proxyBaseUrl);
    if (rawUri.hasScheme) {
      return [rawUri];
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocalhost = host == 'localhost' || host == '127.0.0.1';
      if (isLocalhost && Uri.base.port != 3000) {
        final localUri = Uri.parse(
          'http://localhost:3000${proxyBaseUrl.startsWith('/') ? '' : '/'}$proxyBaseUrl',
        );
        return [localUri, rawUri];
      }
      return [rawUri];
    }

    return [
      Uri.parse(
        'http://localhost:3000${proxyBaseUrl.startsWith('/') ? '' : '/'}$proxyBaseUrl',
      ),
      Uri.parse(
        'http://localhost:8080${proxyBaseUrl.startsWith('/') ? '' : '/'}$proxyBaseUrl',
      ),
    ];
  }
}
