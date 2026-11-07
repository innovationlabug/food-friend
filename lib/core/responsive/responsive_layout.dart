import 'package:flutter/material.dart';

/// Breakpoint width constants for responsive layouts.
class Breakpoints {
  Breakpoints._();

  /// Mobile breakpoint threshold (below this is mobile)
  static const double mobile = 600.0;

  /// Tablet breakpoint threshold (between mobile and desktop)
  static const double desktop = 1024.0;

  /// Standard max width for desktop readable content containers
  static const double maxContentWidth = 1100.0;
}

/// Helper extension on BuildContext to quickly query responsive device tiers.
extension ResponsiveContext on BuildContext {
  /// Screen width from MediaQuery
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height from MediaQuery
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// True if viewport width is less than the mobile breakpoint
  bool get isMobile => screenWidth < Breakpoints.mobile;

  /// True if viewport width is between mobile and desktop breakpoints
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.desktop;

  /// True if viewport width is equal to or greater than desktop breakpoint
  bool get isDesktop => screenWidth >= Breakpoints.desktop;
}

/// Responsive builder widget that selects an appropriate layout
/// based on the available constraints from LayoutBuilder.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Widget builder used for mobile screens (< 600px)
  final WidgetBuilder mobile;

  /// Optional widget builder for tablet screens (600px - 1024px)
  final WidgetBuilder? tablet;

  /// Optional widget builder for desktop screens (>= 1024px)
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop && desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth >= Breakpoints.mobile && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

/// Centers content with a responsive max width constraint for larger viewports.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

