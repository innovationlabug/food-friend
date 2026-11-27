import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/string_normalizer.dart';
import '../../ingredients/domain/receipt_food_item.dart';
import '../../sales/data/sales_matcher_service.dart';
import '../../sales/domain/supermarket_deal.dart';
import '../domain/ingredient_price_entry.dart';
import 'baseline_gtq_price_catalog.dart';

/// Local persistence service for observed ingredient GTQ prices extracted from
/// scanned supermarket receipts and supermarket deal snapshots.
class IngredientPriceStorageService {
  IngredientPriceStorageService({
    SharedPreferences? preferences,
    this.storageKey = defaultStorageKey,
  }) : _preferencesOverride = preferences;

  static const String defaultStorageKey = 'food_friend_ingredient_prices';

  final SharedPreferences? _preferencesOverride;
  SharedPreferences? _cachedPrefs;
  final String storageKey;

  Future<SharedPreferences> get _prefs async {
    return _preferencesOverride ??
        (_cachedPrefs ??= await SharedPreferences.getInstance());
  }

  /// Returns all persisted ingredient GTQ prices indexed by normalized ingredient name.
  Future<Map<String, IngredientPriceEntry>> getPrices() async {
    final prefs = await _prefs;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, IngredientPriceEntry>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, IngredientPriceEntry>{};
      }

      final result = <String, IngredientPriceEntry>{};
      for (final entry in decoded.entries) {
        if (entry.value is Map<String, dynamic>) {
          final parsed = IngredientPriceEntry.fromJson(
            entry.value as Map<String, dynamic>,
          );
          if (parsed.ingredientName.isNotEmpty &&
              parsed.pricePerBaseUnitGtq > 0) {
            result[StringNormalizer.normalize(entry.key)] = parsed;
          }
        }
      }
      return result;
    } catch (_) {
      return <String, IngredientPriceEntry>{};
    }
  }

  /// Persists GTQ prices extracted from confirmed [ReceiptFoodItem]s.
  /// Items without valid positive GTQ prices are skipped gracefully.
  Future<Map<String, IngredientPriceEntry>> savePricesFromReceipt(
    List<ReceiptFoodItem> items, {
    String? supermarket,
    DateTime? savedAt,
  }) async {
    final existing = await getPrices();
    final timestamp = savedAt ?? DateTime.now();
    bool anyUpdated = false;

    for (final item in items) {
      final rawName = item.standardIngredient.trim();
      if (rawName.isEmpty) continue;

      final linePrice = _resolveReceiptLineTotalGtq(item);
      if (linePrice == null || linePrice <= 0) continue;

      final baseline = BaselineGtqPriceCatalog.lookup(rawName);
      final baseUnits = baseline.convertPackageQuantityToBaseUnits(
        item.quantity,
        productName: item.rawName,
        unitCount: item.unitCount,
      );
      if (baseUnits <= 0) continue;

      final rawPerBase = linePrice / baseUnits;
      final unitPrice = _clampUnitPrice(
        rawPerBase,
        baseline.pricePerBaseUnitGtq,
      );

      final key = StringNormalizer.normalize(rawName);
      existing[key] = IngredientPriceEntry(
        ingredientName: rawName,
        priceGtq: item.priceGtq ?? linePrice,
        baseUnit: baseline.baseUnit,
        pricePerBaseUnitGtq: unitPrice,
        source: PriceSource.receipt,
        supermarket: supermarket,
        quantityText: item.quantity,
        updatedAt: timestamp,
      );
      anyUpdated = true;
    }

    if (anyUpdated) {
      await _writeMap(existing);
    }
    return existing;
  }

  /// Persists GTQ prices from active [SupermarketDeal]s without overwriting
  /// fresher or user-scanned receipt prices.
  Future<Map<String, IngredientPriceEntry>> savePricesFromDeals(
    List<SupermarketDeal> deals, {
    DateTime? savedAt,
  }) async {
    final existing = await getPrices();
    final timestamp = savedAt ?? DateTime.now();
    bool anyUpdated = false;

    for (final deal in deals) {
      if (deal.salePriceGtq <= 0) continue;
      final candidateName = deal.queryTerm.trim().isNotEmpty
          ? deal.queryTerm.trim()
          : deal.productName.trim();
      if (candidateName.isEmpty) continue;

      final key = StringNormalizer.normalize(candidateName);
      final current = existing[key];
      if (current != null && current.source == PriceSource.receipt) {
        continue;
      }

      final baseline = BaselineGtqPriceCatalog.lookup(candidateName);
      final baseUnits = baseline.convertPackageQuantityToBaseUnits(
        '',
        productName: deal.productName,
      );
      if (baseUnits <= 0) continue;

      final unitPrice = _clampUnitPrice(
        deal.salePriceGtq / baseUnits,
        baseline.pricePerBaseUnitGtq,
      );

      existing[key] = IngredientPriceEntry(
        ingredientName: baseline.canonicalName,
        priceGtq: deal.salePriceGtq,
        baseUnit: baseline.baseUnit,
        pricePerBaseUnitGtq: unitPrice,
        source: PriceSource.supermarketDeal,
        supermarket: deal.supermarketName,
        quantityText: deal.productName,
        updatedAt: timestamp,
      );
      anyUpdated = true;
    }

    if (anyUpdated) {
      await _writeMap(existing);
    }
    return existing;
  }

  /// Converts a [SupermarketDeal] into a normalized price per base unit
  /// for [ingredientName], or `null` if it does not match.
  static double? dealPricePerBaseUnit(
    SupermarketDeal deal,
    String ingredientName,
    BaselineIngredientPrice baseline,
  ) {
    if (deal.salePriceGtq <= 0 ||
        !SalesMatcherService.matchesDeal(deal, ingredientName)) {
      return null;
    }

    final baseUnits = baseline.convertPackageQuantityToBaseUnits(
      '',
      productName: deal.productName,
    );
    if (baseUnits <= 0) return null;

    return _clampUnitPrice(
      deal.salePriceGtq / baseUnits,
      baseline.pricePerBaseUnitGtq,
    );
  }

  Future<void> clearPrices() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
  }

  Future<void> _writeMap(Map<String, IngredientPriceEntry> map) async {
    final prefs = await _prefs;
    final serialized = <String, dynamic>{
      for (final entry in map.entries) entry.key: entry.value.toJson(),
    };
    await prefs.setString(storageKey, jsonEncode(serialized));
  }

  static double? _resolveReceiptLineTotalGtq(ReceiptFoodItem item) {
    if (item.totalPriceGtq != null && item.totalPriceGtq! > 0) {
      return item.totalPriceGtq!;
    }
    if (item.priceGtq != null && item.priceGtq! > 0) {
      return item.priceGtq! * math.max(1, item.unitCount);
    }
    return null;
  }

  static double _clampUnitPrice(double observed, double baseline) {
    final minAllowed = baseline * 0.15;
    final maxAllowed = baseline * 6.0;
    return observed.clamp(minAllowed, maxAllowed);
  }
}
