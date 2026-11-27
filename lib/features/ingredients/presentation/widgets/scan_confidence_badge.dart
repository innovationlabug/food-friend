import 'package:flutter/material.dart';

/// Compact badge shown only for uncertain scanned items (`medium` / `low`
/// confidence) in photo and receipt scanners. High-confidence items render
/// nothing to keep the checklist uncluttered.
class ScanConfidenceBadge extends StatelessWidget {
  const ScanConfidenceBadge({
    super.key,
    required this.confidence,
    this.compact = false,
  });

  /// Normalized confidence level (`'high'`, `'medium'`, or `'low'`).
  final String confidence;

  /// Uses slightly tighter padding and font size (e.g., below price on receipts).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = confidence.toLowerCase();
    if (normalized == 'high') {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isLow = normalized == 'low';
    final label = isLow ? 'Poco claro' : 'Por verificar';
    final tooltipMessage = isLow
        ? 'No estamos seguros de este producto; verifica que sea correcto antes de agregarlo.'
        : 'La detección no es completamente segura; confirma si corresponde al ingrediente.';

    final Color badgeColor = isLow
        ? (isDark ? Colors.grey.shade400 : Colors.grey.shade700)
        : (isDark ? Colors.amber.shade300 : Colors.amber.shade800);

    return Tooltip(
      message: tooltipMessage,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: badgeColor,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 10 : null,
          ),
        ),
      ),
    );
  }
}
