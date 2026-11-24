import 'package:flutter/material.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../data/sales_matcher_service.dart';

/// In-app Spanish notification banner alerting the user when frequent,
/// favorite-recipe, or `"Por comprar"` ingredients are on sale in GTQ.
class SalesAlertBanner extends StatelessWidget {
  const SalesAlertBanner({
    super.key,
    required this.report,
    required this.onTapViewDeals,
    this.compact = false,
  });

  final SalesMatchReport report;
  final VoidCallback onTapViewDeals;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!report.hasMatches) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = report.matchedDeals.length;
    final title = compact
        ? (count == 1
            ? '1 oferta en tus ingredientes frecuentes'
            : '$count ofertas en tus ingredientes frecuentes')
        : (count == 1
            ? '1 oferta en tus ingredientes'
            : '$count ofertas en tus ingredientes');

    final subtitle = report.shoppingListMatchesCount > 0
        ? '${report.shoppingListMatchesCount} en Por comprar • Ahorra hasta ${report.formattedTotalSavings}'
        : 'Ahorra hasta ${report.formattedTotalSavings} en supermercados locales';

    return Card(
      key: const ValueKey('sales_alert_banner'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTapViewDeals,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 12,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 6 : 9),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
                child: AppSvgIcon(
                  assetName: 'store',
                  size: compact ? 16 : 20,
                  color: colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: (compact
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.titleMedium)
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onTapViewDeals,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: compact ? Size.zero : null,
                  tapTargetSize: compact
                      ? MaterialTapTargetSize.shrinkWrap
                      : MaterialTapTargetSize.padded,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 6 : 8,
                  ),
                ),
                child: const Text('Ver ofertas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
