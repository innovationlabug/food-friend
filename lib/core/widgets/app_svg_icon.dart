import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable SVG icon widget using flutter_svg.
/// Enforces standard sizing and theme-based coloring without emoji characters.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.assetName,
    this.size = 24.0,
    this.color,
    this.semanticsLabel,
  });

  /// Name of the SVG file in assets/icons/ (with or without .svg extension)
  final String assetName;

  /// Width and height of the icon square
  final double size;

  /// Icon tint color. Defaults to current IconTheme or ColorScheme.onSurface.
  final Color? color;

  /// Accessibility label for screen readers
  final String? semanticsLabel;

  String get _normalizedPath {
    final cleanName = assetName.endsWith('.svg') ? assetName : '$assetName.svg';
    return 'assets/icons/$cleanName';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      _normalizedPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      semanticsLabel: semanticsLabel,
    );
  }
}

