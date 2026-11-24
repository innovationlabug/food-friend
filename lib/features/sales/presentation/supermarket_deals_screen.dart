import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../shopping_list/data/shopping_list_storage_service.dart';
import '../data/sales_matcher_service.dart';
import '../data/sales_service.dart';
import '../domain/matched_sale_deal.dart';
import '../domain/supermarket.dart';

/// Screen displaying matched and general supermarket deals in Guatemalan Quetzales (Q),
/// with supermarket filters, favorite-store toggling, and one-tap addition to `"Por comprar"`.
class SupermarketDealsScreen extends StatefulWidget {
  const SupermarketDealsScreen({
    super.key,
    this.salesService,
    this.salesMatcherService,
    this.shoppingListService,
  });

  final SalesService? salesService;
  final SalesMatcherService? salesMatcherService;
  final ShoppingListStorageService? shoppingListService;

  @override
  State<SupermarketDealsScreen> createState() => _SupermarketDealsScreenState();
}

class _SupermarketDealsScreenState extends State<SupermarketDealsScreen> {
  late final SalesService _salesService;
  late final SalesMatcherService _matcherService;
  late final ShoppingListStorageService _shoppingListService;

  SalesMatchReport? _report;
  List<Supermarket> _supermarkets = Supermarket.knownSupermarkets;
  bool _isLoading = true;
  bool _showOnlyMatches = true;
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _salesService = widget.salesService ?? SalesService();
    _shoppingListService =
        widget.shoppingListService ?? ShoppingListStorageService();
    _matcherService = widget.salesMatcherService ??
        SalesMatcherService(
          salesService: _salesService,
          shoppingListService: _shoppingListService,
        );
    _loadDeals();
  }

  Future<void> _loadDeals({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait<dynamic>([
      _matcherService.loadAndMatch(forceRefresh: forceRefresh),
      _salesService.getSupermarkets(),
    ]);

    if (!mounted) return;
    final report = results[0] as SalesMatchReport;
    final stores = results[1] as List<Supermarket>;

    setState(() {
      _report = report;
      _supermarkets = stores;
      // Default to all deals if the user has no personal matches yet
      if (!report.hasMatches) {
        _showOnlyMatches = false;
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleFavoriteStore(String storeId) async {
    final currentFav = _supermarkets
        .where((s) => s.isFavorite)
        .map((s) => s.id)
        .firstOrNull;
    final nextFav = currentFav == storeId ? null : storeId;
    await _salesService.setFavoriteSupermarketId(nextFav);
    await _loadDeals();
  }

  Future<void> _addDealToShoppingList(MatchedSaleDeal matchedDeal) async {
    if (matchedDeal.isInShoppingList) return;
    final itemName = matchedDeal.suggestedShoppingItemName;
    await _shoppingListService.addIngredient(Ingredient(name: itemName));
    await _loadDeals();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"$itemName" agregado a tu lista Por comprar'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  List<MatchedSaleDeal> _filteredDeals(SalesMatchReport report) {
    final source = _showOnlyMatches ? report.matchedDeals : report.allDeals;
    if (_selectedStoreId == null) return source;
    return source
        .where((item) => item.deal.supermarketId == _selectedStoreId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      drawer: const AppNavigationDrawer(
        currentDestination: AppDestination.shoppingList,
      ),
      appBar: AppBar(
        leadingWidth: appBarLeadingWidth(context),
        leading: const AppBarLeading(),
        title: const Text(
          'Ofertas del supermercado',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar ofertas',
            onPressed: _isLoading ? null : () => _loadDeals(forceRefresh: true),
            icon: AppSvgIcon(
              assetName: 'refresh',
              size: 20,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final report = _report;
    if (report == null) {
      return const Center(
        child: Text('No hay ofertas disponibles en este momento.'),
      );
    }

    final deals = _filteredDeals(report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterControls(colorScheme, report),
        const SizedBox(height: 12),
        Expanded(
          child: deals.isEmpty
              ? _buildEmptyFilterState(theme, colorScheme)
              : _buildDealsList(context, deals),
        ),
      ],
    );
  }

  Widget _buildFilterControls(
    ColorScheme colorScheme,
    SalesMatchReport report,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          selected: _showOnlyMatches,
          label: Text('Para ti (${report.matchedDeals.length})'),
          onSelected: (_) => setState(() => _showOnlyMatches = true),
        ),
        FilterChip(
          selected: !_showOnlyMatches,
          label: Text('Todas (${report.allDeals.length})'),
          onSelected: (_) => setState(() => _showOnlyMatches = false),
        ),
        for (final store in _supermarkets)
          InputChip(
            selected: _selectedStoreId == store.id,
            label: Text(store.name),
            onSelected: (selected) {
              setState(() {
                _selectedStoreId = selected ? store.id : null;
              });
            },
            onDeleted: () => _toggleFavoriteStore(store.id),
            deleteIcon: AppSvgIcon(
              assetName: 'heart',
              size: 16,
              color: store.isFavorite
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
            deleteButtonTooltipMessage: store.isFavorite
                ? 'Quitar supermercado favorito'
                : 'Marcar como supermercado favorito',
          ),
      ],
    );
  }

  Widget _buildEmptyFilterState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetName: 'store',
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay ofertas con los filtros seleccionados.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_showOnlyMatches)
              FilledButton.tonal(
                onPressed: () => setState(() => _showOnlyMatches = false),
                child: const Text('Ver todas las ofertas'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsList(BuildContext context, List<MatchedSaleDeal> deals) {
    if (!context.isDesktop) {
      return ListView.separated(
        itemCount: deals.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildDealCard(context, deals[index]),
      );
    }

    final rowCount = (deals.length + 1) ~/ 2;
    return ListView.separated(
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, rowIndex) {
        final first = rowIndex * 2;
        final second = first + 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildDealCard(context, deals[first])),
              const SizedBox(width: 10),
              Expanded(
                child: second < deals.length
                    ? _buildDealCard(context, deals[second])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDealCard(BuildContext context, MatchedSaleDeal matchedDeal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deal = matchedDeal.deal;
    final primaryReason =
        matchedDeal.reasons.isNotEmpty ? matchedDeal.reasons.first.label : null;

    final secondaryPriceStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Card(
      key: ValueKey('supermarket_deal_${deal.id}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: matchedDeal.isMatched
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.supermarketName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  deal.productName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (primaryReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    primaryReason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      deal.formattedSalePrice,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            deal.formattedRegularPrice,
                            style: secondaryPriceStyle?.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            'Ahorras ${deal.formattedSavings}',
                            style: secondaryPriceStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                matchedDeal.isInShoppingList
                    ? FilledButton.tonalIcon(
                        onPressed: null,
                        icon: const AppSvgIcon(assetName: 'check', size: 16),
                        label: const Text('En Por comprar'),
                      )
                    : FilledButton.icon(
                        onPressed: () => _addDealToShoppingList(matchedDeal),
                        icon: AppSvgIcon(
                          assetName: 'plus',
                          size: 16,
                          color: colorScheme.onPrimary,
                        ),
                        label: const Text('Agregar a lista de compras'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
